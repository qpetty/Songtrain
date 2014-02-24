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
    
    uint8_t buffer[8000];
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
    myInfo.bytesThatNeedToBeFilled = myInfo.bufferByteSize;
    myInfo.mNumPacketsToRead = 0;
    myInfo.inputStream = (__bridge_retained CFReadStreamRef)input;

    //Need to create an array for audiostreampacketdescriptions to be added to enqueue buffer
    
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
        //NSLog(@"Read %ld bytes from input stream after Queue has been set up\n", (long)bufferSize);
        error = AudioFileStreamParseBytes(myInfo.streamID, (UInt32)bufferSize, buffer, 0);
    } while (myInfo.nextBufferToBeFilled != 0 || myInfo.readyToPlay == NO);
    
    /*
    error = AudioQueuePrime(myInfo.mQueue, 0, NULL);
    
    if (error) {
        char errorString[7];
        FormatError(errorString, error);
        NSLog(@"Error priming audioQueue: %s\n", errorString);
    }
     */
    
    NSLog(@"Audio Queue Start!\n");
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
    
    NSLog(@"Audio Stream Services Property Callback: %c\n", inPropertyID);
    
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

        NSLog(@"Ready for some audio!\n");
        myInfo->readyToPlay = YES;
        OSStatus error = AudioQueueNewOutput(&myInfo->mDataFormat, bufferFromQueueAvailable, inClientData, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &myInfo->mQueue);
        
        if (error) {
            char errorString[7];
            FormatError(errorString, error);
            NSLog(@"Error priming audioQueue: %s\n", errorString);
        }
        
        for (int i = 0; i < kNumberBuffers; i++) {
            OSStatus error = AudioQueueAllocateBuffer (myInfo->mQueue, myInfo->bufferByteSize, &myInfo->mBuffers[i]);
            NSLog(@"Just allocated: %d\n", myInfo->mBuffers[i]);
            NSLog(@"Just called queue allocate buffer with error code: %d\n", (int)error);
        }
        
        AudioQueueSetParameter (myInfo->mQueue, kAudioQueueParam_Volume, 1.0);
    }
    else if (inPropertyID == kAudioFileStreamProperty_FileFormat){
        NSLog(@"Found FileFormate\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_FormatList){
        NSLog(@"Found FormatList\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_MagicCookieData){
        NSLog(@"Found Magic Cookie data\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_AudioDataByteCount){
        NSLog(@"Found data bytes count\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_AudioDataPacketCount){
        NSLog(@"Found data packet count\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_MaximumPacketSize){
        NSLog(@"Found max packet size\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_DataOffset){
        NSLog(@"Found data offsett\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_ChannelLayout){
        NSLog(@"Found channel layout\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_PacketToFrame){
        NSLog(@"Found packet to frame\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_FrameToPacket){
        NSLog(@"Found frame to packet\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_PacketToByte){
        NSLog(@"Found packet to byte\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_ByteToPacket){
        NSLog(@"Found byte to packet\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_PacketTableInfo){
        NSLog(@"Found packet table info\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_PacketSizeUpperBound){
        NSLog(@"Found packet size upper bound\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_AverageBytesPerPacket){
        NSLog(@"Found average bytes per packet\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_BitRate){
        NSLog(@"Found bitrate\n");
    }
}

void fileStreamDataCallback(void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void *inInputData,
                                    AudioStreamPacketDescription *inPacketDescriptions)
{
    struct myAQStruct *myInfo = (struct myAQStruct *)inClientData;
    
    NSLog(@"Audio Stream Services Data Callback\n");
    
    
    if (myInfo->bytesThatNeedToBeFilled < inNumberBytes) {
        myInfo->mBuffers[myInfo->nextBufferToBeFilled]->mAudioDataByteSize = myInfo->bufferByteSize - myInfo->bytesThatNeedToBeFilled;
        
        NSLog(@"enqueing buffer: %d with %d bytes and %d packets to read\n", (unsigned int)myInfo->nextBufferToBeFilled, myInfo->bufferByteSize, (unsigned int)myInfo->mNumPacketsToRead);
        OSStatus error = AudioQueueEnqueueBuffer(myInfo->mQueue, myInfo->mBuffers[myInfo->nextBufferToBeFilled++], myInfo->mNumPacketsToRead, NULL);
        
        if (error) {
            char errorString[7];
            FormatError(errorString, error);
            NSLog(@"Error in enqueue buffer: %s\n", errorString);
        }
        
        if (myInfo->nextBufferToBeFilled == kNumberBuffers) {
            myInfo->nextBufferToBeFilled = 0;
            myInfo->readyToPlay = YES;
        }
        
        myInfo->bytesThatNeedToBeFilled = myInfo->bufferByteSize;
        myInfo->mNumPacketsToRead = 0;
    }
    
    //Only for one packet at a time
    myInfo->mNumPacketsToRead++;
    memcpy(myInfo->mBuffers[myInfo->nextBufferToBeFilled]->mAudioData, inInputData, inNumberBytes);
    myInfo->bytesThatNeedToBeFilled -= inNumberBytes;
}

static void bufferFromQueueAvailable(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inCompleteAQBuffer) {
    struct myAQStruct *myInfo = (struct myAQStruct *)inUserData;
    uint8_t buffer[16000];
    
    static int totalFromOut = 0;
    
    int currentBuffer = myInfo->nextBufferToBeFilled;
    
    /*
    while (currentBuffer == myInfo->nextBufferToBeFilled) {
        
        NSLog(@"Next buffer: %d\n", myInfo->nextBufferToBeFilled);
        
        if (CFReadStreamHasBytesAvailable(myInfo->inputStream)) {
               
        
            NSLog(@"Trying to read %ld bytes for next buffer\n", (CFIndex)sizeof(buffer));
            CFIndex bufferSize = CFReadStreamRead(myInfo->inputStream, buffer, (CFIndex)sizeof(buffer));
            totalFromOut += bufferSize;
            NSLog(@"Just read %ld bytes for next buffer\n", bufferSize);
            OSStatus error = AudioFileStreamParseBytes(myInfo->streamID, (UInt32)bufferSize, buffer, 0);
        
            if (error) {
                char errorString[7];
                FormatError(errorString, error);
                NSLog(@"Error in enqueue buffer: %s\n", errorString);
            }
        }
        else{
            NSLog(@"No Bytes available, at %d\n", totalFromOut);
        }
    }
     */

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
