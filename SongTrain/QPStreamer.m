//
//  QPStreamer.m
//  SongTrain
//
//  Created by Quinton Petty on 2/23/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "QPStreamer.h"

@implementation QPStreamer{
    
    NSInputStream *input;
    NSThread *musicThread;
    struct myAQStruct myInfo;
    
    uint8_t buffer[16000];
}

static const int minBufferSize = 0x4000;

- (void)setInputStream:(NSInputStream*)inputStream
{
    input = inputStream;
    
    if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        return [self performSelectorOnMainThread:@selector(makeThread) withObject:nil waitUntilDone:YES];
    }
    
    [self makeThread];
}

- (void)makeThread
{
    NSLog(@"Allocating and starting music thread\n");
    musicThread = [[NSThread alloc] initWithTarget:self selector:@selector(start) object:nil];
    [musicThread start];
}
    
- (void)start
{
    
    OSStatus error = AudioFileStreamOpen(&myInfo, fileStreamPropertyCallback, fileStreamDataCallback, kAudioFileMP1Type, &myInfo.streamID);
    if (error) {
        char errorString[7];
        FormatError(errorString, error);
        NSLog(@"Error opening file stream: %s\n", errorString);
    }
    
    myInfo.readyToPlay = NO;
    myInfo.bufferByteSize = minBufferSize;
    myInfo.nextBufferToBeFilled = 0;
    myInfo.inputStream = (__bridge_retained CFReadStreamRef)input;
    
    [input open];
    
    while (!myInfo.readyToPlay) {
        NSLog(@"Stream Status: %u\n", input.streamStatus);
        NSLog(@"Reading from Input Stream %lu bytes\n", sizeof(buffer));
        NSInteger bufferSize = [input read:buffer maxLength:sizeof(buffer)];
        NSLog(@"Read %ld bytes from input stream\n", (long)bufferSize);
        error = AudioFileStreamParseBytes(myInfo.streamID, (UInt32)bufferSize, buffer, 0);
        
        if (error) {
            char errorString[7];
            FormatError(errorString, error);
            NSLog(@"Error in stream parsing bytes: %s\n", errorString);
        }
    }
    
    myInfo.readyToPlay = NO;
    
    do {
        NSInteger bufferSize = [input read:buffer maxLength:sizeof(buffer)];
        NSLog(@"Read %ld bytes from input stream after Queue has been set up\n", (long)bufferSize);
        error = AudioFileStreamParseBytes(myInfo.streamID, (UInt32)bufferSize, buffer, 0);
    } while (myInfo.nextBufferToBeFilled != 0 || myInfo.readyToPlay == NO);
    
    AudioQueuePrime(myInfo.mQueue, 0, NULL);
    
    error = AudioQueueStart(myInfo.mQueue, 0);
    
    if (error) {
        char errorString[7];
        FormatError(errorString, error);
        NSLog(@"Error starting audioQueue: %s\n", errorString);
    }
    
    while (1 && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

void fileStreamPropertyCallback(void *inClientData, AudioFileStreamID inAudioFileStream, AudioFileStreamPropertyID inPropertyID, UInt32 *ioFlags)
{
    struct myAQStruct *myInfo = (struct myAQStruct *)inClientData;
    UInt32 propertySize;
    
    NSLog(@"Audio Stream Services Property Callback\n");
    
    if (inPropertyID == kAudioFileStreamProperty_DataFormat) {
        propertySize = sizeof(AudioStreamBasicDescription);
        AudioFileStreamGetProperty(inAudioFileStream, inPropertyID, &propertySize, &myInfo->mDataFormat);
        if (propertySize == sizeof(myInfo->mDataFormat)) {
            NSLog(@"Entire AudioStreamBasicDescription found\n");
        }
    }
    else if (inPropertyID == kAudioFileStreamProperty_ReadyToProducePackets) {
        UInt32 ready;
        AudioFileStreamGetProperty(inAudioFileStream, inPropertyID, &propertySize, &ready);
        NSLog(@"Produce Packets found :%d!\n", ready);
        
        if (1) {
            NSLog(@"Ready for some audio!\n");
            myInfo->readyToPlay = YES;
            AudioQueueNewOutput(&myInfo->mDataFormat, bufferFromQueueAvailable, inClientData, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &myInfo->mQueue);
            
            for (int i = 0; i < kNumberBuffers; i++) {
                OSStatus error = AudioQueueAllocateBuffer (myInfo->mQueue, myInfo->bufferByteSize, &myInfo->mBuffers[i]);
                NSLog(@"Just allocated: %d\n", myInfo->mBuffers[i]);
                NSLog(@"Just called queue allocate buffer with error code: %d\n", (int)error);
            }
            
            AudioQueueSetParameter (myInfo->mQueue, kAudioQueueParam_Volume, 1.0);
        }
    }
}

void fileStreamDataCallback(void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void *inInputData,
                                    AudioStreamPacketDescription *inPacketDescriptions)
{
    struct myAQStruct *myInfo = (struct myAQStruct *)inClientData;
    
    NSLog(@"Audio Stream Services Data Callback\n");
    
    NSLog(@"Nextbuff: %d   inNumberBytes: %u\n", myInfo->nextBufferToBeFilled, (unsigned int)inNumberBytes);
    
    //int nextbuff = myInfo->nextBufferToBeFilled;
    //NSLog(@"Trying to enqueue %d\n", myInfo->mBuffers[nextbuff]);
    memcpy(myInfo->mBuffers[myInfo->nextBufferToBeFilled]->mAudioData, inInputData, inNumberBytes);
    
    myInfo->mBuffers[myInfo->nextBufferToBeFilled]->mAudioDataByteSize = inNumberBytes;
    AudioQueueEnqueueBuffer(myInfo->mQueue, myInfo->mBuffers[myInfo->nextBufferToBeFilled++], inNumberPackets, inPacketDescriptions);
    
    if (myInfo->nextBufferToBeFilled == kNumberBuffers) {
        myInfo->nextBufferToBeFilled = 0;
        myInfo->readyToPlay = YES;
    }
}

static void bufferFromQueueAvailable(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inCompleteAQBuffer) {
    struct myAQStruct *myInfo = (struct myAQStruct *)inUserData;
    uint8_t buffer[16000];
    
    NSLog(@"Trying to read %ld bytes for next buffer\n", (CFIndex)sizeof(buffer));
    CFIndex bufferSize = CFReadStreamRead(myInfo->inputStream, buffer, (CFIndex)sizeof(buffer));
    NSLog(@"Just read %ld bytes for next buffer\n", bufferSize);
    AudioFileStreamParseBytes(myInfo->streamID, (UInt32)bufferSize, buffer, 0);
}

static char *FormatError(char *str, OSStatus error)
{
    // see if it appears to be a 4-char-code
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
    return str;
}

@end
