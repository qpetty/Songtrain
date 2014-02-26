//
//  QPInputStreamer.m
//  SongTrain
//
//  Created by Quinton Petty on 2/25/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "QPInputStreamer.h"

@implementation QPInputStreamer{
    
    NSInputStream *input;
    NSThread *musicThread;
    struct AudioStreamInfo myInfo;
}


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
    myInfo.packetListHead = NULL;
    myInfo.packetListTail = NULL;
    myInfo.packetsInList = 0;
    
    NSLog(@"Setting delegate and scheculing in run loop\n");
    input.delegate = self;
    [input scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [input open];
    
    while ([[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ;
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    uint8_t buffer[2048];
    NSInteger length;
    
    if (eventCode == NSStreamEventHasBytesAvailable){
        length = [(NSInputStream*)aStream read:buffer maxLength:sizeof(buffer)];
       // NSLog(@"Read %d bytes\n", length);
        OSStatus error = AudioFileStreamParseBytes(myInfo.streamID, (UInt32)length, buffer, 0);
        
        if (error) {
            char errorString[7];
            FormatError(errorString, error);
            NSLog(@"Error in stream parsing bytes: %s\n", errorString);
        }

    }
    else if (eventCode == NSStreamEventEndEncountered){
        NSLog(@"No More!\n");
    }
    else if (eventCode == NSStreamEventOpenCompleted){
        NSLog(@"Opened!\n");
    }
}

void fileStreamPropertyCallback(void *inClientData, AudioFileStreamID inAudioFileStream, AudioFileStreamPropertyID inPropertyID, UInt32 *ioFlags)
{
    struct AudioStreamInfo *myInfo = (struct AudioStreamInfo *)inClientData;
    UInt32 propertySize;
    
    NSLog(@"found property '%c%c%c%c'\n", (char)(inPropertyID>>24)&255, (char)(inPropertyID>>16)&255, (char)(inPropertyID>>8)&255, (char)inPropertyID&255);
    
    if (inPropertyID == kAudioFileStreamProperty_DataFormat) {
        propertySize = sizeof(AudioStreamBasicDescription);
        AudioFileStreamGetProperty(inAudioFileStream, inPropertyID, &propertySize, &myInfo->basicDescription);
        if (propertySize == sizeof(myInfo->basicDescription)) {
            NSLog(@"Entire AudioStreamBasicDescription found\n");
        }
    }
    else if (inPropertyID == kAudioFileStreamProperty_ReadyToProducePackets) {
        
        
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
    struct AudioStreamInfo *myInfo = (struct AudioStreamInfo *)inClientData;
    
    //NSLog(@"Audio Stream Services Data Callback\n");
    
    for (int i = 0; i < inNumberPackets; i++) {
        addPacketToList(myInfo, inPacketDescriptions[i].mVariableFramesInPacket, inPacketDescriptions[i].mDataByteSize, inInputData + inPacketDescriptions[i].mStartOffset);
    }
}

void addPacketToList(struct AudioStreamInfo *streamInfo, UInt32 numFrames, UInt32 packetSize, void *data)
{
    struct AudioPacket *newPacket = malloc(sizeof(struct AudioPacket));
    
    static bool started = NO;
    
    newPacket->packetSize = packetSize;
    newPacket->numFrames = numFrames;
    newPacket->data = malloc(packetSize);
    memcpy(newPacket->data, data, packetSize);
    newPacket->next = NULL;
    
    //If the first item in the queue then assign both head and tail to the new item
    if (!streamInfo->packetListTail)
        streamInfo->packetListHead = newPacket;
    else
        streamInfo->packetListTail->next = newPacket;

    streamInfo->packetListTail = newPacket;
    streamInfo->packetsInList++;
    
    if (streamInfo->packetsInList > 40 && !started) {
        startMyQueue(streamInfo);
        started = YES;
    }
}

void fillBufferFromPacketQueue(struct AudioStreamInfo *streamInfo, AudioQueueBufferRef inBuffer)
{
    streamInfo->packetsFilled = 0;
    //inBuffer->mAudioDataByteSize = 0;
    //NSLog(@"Buffer Data Capacity: %u   Buffer Data Size %u    Next Packet Size: %u\n", inBuffer->mAudioDataBytesCapacity, inBuffer->mAudioDataByteSize, streamInfo->packetListHead->packetSize);
    while (streamInfo->packetListHead && inBuffer->mAudioDataBytesCapacity - inBuffer->mAudioDataByteSize > streamInfo->packetListHead->packetSize) {
        struct AudioPacket *temp = streamInfo->packetListHead;
        streamInfo->packetListHead = temp->next;
        
        NSLog(@"Filling Packet %u\n", (unsigned int)streamInfo->packetsFilled);
        
        memcpy(inBuffer->mAudioData + inBuffer->mAudioDataByteSize, temp->data, temp->packetSize);
        
        streamInfo->packetDescription[streamInfo->packetsFilled].mStartOffset = inBuffer->mAudioDataByteSize;
        streamInfo->packetDescription[streamInfo->packetsFilled].mVariableFramesInPacket = temp->numFrames;
        streamInfo->packetDescription[streamInfo->packetsFilled].mDataByteSize = temp->packetSize;
        
        inBuffer->mAudioDataByteSize += temp->packetSize;
        streamInfo->packetsFilled++;
    }
}

void startMyQueue(struct AudioStreamInfo *streamInfo)
{
    OSStatus error = AudioQueueNewOutput(&streamInfo->basicDescription, bufferFromQueueAvailable, streamInfo, 0, 0, 0, &streamInfo->audioQueue);
    
    if (error) {
        char errorString[7];
        FormatError(errorString, error);
        NSLog(@"Error making new queue audioQueue: %s\n", errorString);
    }
    
    for (int i = 0; i < kNumberBuffers; i++) {
        AudioQueueBufferRef newBufferRef;
        OSStatus error = AudioQueueAllocateBuffer (streamInfo->audioQueue, kBufferSize, &newBufferRef);
        //NSLog(@"Just allocated: %d\n", newBufferRef);
        
        bufferFromQueueAvailable(streamInfo, streamInfo->audioQueue, newBufferRef);
        
        /*
        fillBufferFromPacketQueue(streamInfo, newBufferRef);
        error = AudioQueueEnqueueBuffer(streamInfo->audioQueue, newBufferRef, streamInfo->packetsFilled, streamInfo->packetDescription);
        NSLog(@"Just called enqueue buffer with error code: %d\n", (int)error);
         */
    }
    
    AudioQueueSetParameter (streamInfo->audioQueue, kAudioQueueParam_Volume, 1.0);
    error = AudioQueueStart(streamInfo->audioQueue, 0);
    if (error) {
        char errorString[7];
        FormatError(errorString, error);
        NSLog(@"Error starting audioQueue: %s\n", errorString);
    }
    
    NSLog(@"Started Audio Queue\n");
}

static void bufferFromQueueAvailable(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inCompleteAQBuffer)
{
    struct AudioStreamInfo *streamInfo = (struct AudioStreamInfo *)inUserData;
    
    //NSLog(@"bufferFromQueueAvailable\n");
    fillBufferFromPacketQueue(streamInfo, inCompleteAQBuffer);
    OSStatus error = AudioQueueEnqueueBuffer(streamInfo->audioQueue, inCompleteAQBuffer, streamInfo->packetsFilled, streamInfo->packetDescription);
    NSLog(@"Just called enqueue buffer with error code: %d\n", (int)error);
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
