//
//  RemoteSong.m
//  SongTrain
//
//  Created by Quinton Petty on 5/2/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "RemoteSong.h"

@implementation RemoteSong {
    BOOL sentRequest;
    
    NSThread *streamingThread;
    BOOL stillStreaming, isFormatVBR;
    
    TPCircularBuffer cBuffer;
    AudioConverterRef converter;
    AudioStreamPacketDescription aspds[256];
    uint8_t *audioData;
}

- (instancetype)initWithSong:(Song*)song fromPeer:(MCPeerID*)peer andOutputASBD:(AudioStreamBasicDescription)audioStreamBD
{
    if (self = [super initWithOutputASBD:audioStreamBD]) {
        self.peer = peer;
        self.title = song.title;
        self.artistName = song.artistName;
        self.persistantID = song.persistantID;
        self.url = song.url;
        self.songLength = song.songLength;
        
        image = nil;
        sentRequest = NO;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.peer = [coder decodeObjectForKey:@"peer"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:self.peer forKey:@"peer"];
}

- (void)prepareSong{
    [[QPSessionManager sessionManager] requestToStartStreaming:self];
    
    TPCircularBufferInit(&cBuffer, kBufferLength);
    AudioFileStreamOpen((__bridge void*)self, propertyListenerCallback, packetCallback, 0, &(_fileStream));
}

- (void)setInStream:(NSInputStream *)inStream
{
    _inStream = inStream;
    [self startStreaming];
}

- (void)startStreaming
{
    if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        return [self performSelectorOnMainThread:@selector(startStreaming) withObject:nil waitUntilDone:YES];
    }
    
    self.inStream.delegate = self;
    stillStreaming = YES;
    streamingThread = [[NSThread alloc] initWithTarget:self selector:@selector(startThread) object:nil];
    [streamingThread start];
}

- (void)startThread
{
    [self.inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inStream open];
    while (stillStreaming && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ;
}


// Well Shit -> http://stackoverflow.com/questions/4051018/nsinputstream-getbuffer-length-doesnt-work
// [incomingStream getBuffer:&buff length:&len] would have been nice.
-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    if (eventCode == NSStreamEventHasBytesAvailable) {
        NSInputStream *incomingStream = (NSInputStream*)aStream;
        uint8_t buf[4096];
        
        NSInteger ret = [incomingStream read:buf maxLength:4096];
        if (ret < 0) {
            NSLog(@"Failed to read from input stream\n");
        }
        else if (ret == 0) {
            NSLog(@"End of Buffer found\n");
        }
        else {
            AudioFileStreamParseBytes(_fileStream, (UInt32)ret, buf, 0);
        }
    }
    else if (eventCode == NSStreamEventEndEncountered) {
        //close loop
        stillStreaming = NO;
    }
}


void propertyListenerCallback(void *inClientData, AudioFileStreamID inAudioFileStream, AudioFileStreamPropertyID inPropertyID, UInt32 *ioFlags)
{
    RemoteSong *myInfo = (__bridge RemoteSong *)(inClientData);
    UInt32 propertySize;
    
    NSLog(@"found property '%c%c%c%c'\n", (char)(inPropertyID>>24)&255, (char)(inPropertyID>>16)&255, (char)(inPropertyID>>8)&255, (char)inPropertyID&255);
    
    if (inPropertyID == kAudioFileStreamProperty_DataFormat) {
        propertySize = sizeof(AudioStreamBasicDescription);
        AudioFileStreamGetProperty(inAudioFileStream, inPropertyID, &propertySize, myInfo->inputASBD);
        myInfo->isFormatVBR = (myInfo->inputASBD->mBytesPerPacket == 0 || myInfo->inputASBD->mFramesPerPacket == 0);
        AudioConverterNew(myInfo->inputASBD, myInfo->outputASBD, &myInfo->converter);
    }
    else if (inPropertyID == kAudioFileStreamProperty_ReadyToProducePackets) {
        NSLog(@"Ready to make some packets\n");
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

void packetCallback(void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void *inInputData, AudioStreamPacketDescription *inPacketDescriptions)
{
    NSLog(@"Got %lu packets\n", inNumberPackets);
    RemoteSong *myInfo = (__bridge RemoteSong *)(inClientData);
    
    int32_t spaceAvailableInBuffer;
    uint8_t *buffer;
    size_t offset = 0;
    
    buffer = TPCircularBufferHead(&myInfo->cBuffer, &spaceAvailableInBuffer);
    
    if (spaceAvailableInBuffer <= kBufferLength / 5) {
        return;
    }
    
    for (int i = 0; i < inNumberPackets; i++) {
        
        if (myInfo->isFormatVBR) {
            memcpy(buffer + offset, inPacketDescriptions + i, sizeof(AudioStreamPacketDescription));
            offset += sizeof(AudioStreamPacketDescription);
            memcpy(buffer + offset, ((uint8_t*)inInputData) + inPacketDescriptions->mStartOffset, inPacketDescriptions->mDataByteSize);
            offset += inPacketDescriptions->mDataByteSize;
        }
        else {
            memcpy(buffer + offset, ((uint8_t*)inInputData) + (myInfo->inputASBD->mBytesPerPacket * i), myInfo->inputASBD->mBytesPerPacket);
            offset += myInfo->inputASBD->mBytesPerPacket;
        }
    }
    
    TPCircularBufferProduce(&myInfo->cBuffer, (int)offset);
}

- (int)getMusicPackets:(UInt32*)numOfPackets forBuffer:(AudioBufferList*)ioData
{
    OSStatus err = AudioConverterFillComplexBuffer(converter, converterCallback, (__bridge void*)self, numOfPackets, ioData, NULL);
    //NSLog(@"Number of out Packets: %u\n", *numOfPackets);
    return err;
}

OSStatus converterCallback(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription  **outDataPacketDescription, void *inUserData)
{
    RemoteSong *myInfo = (__bridge RemoteSong *)inUserData;
    
    int32_t spaceAvailableInBuffer;
    uint8_t *buffer;
    int goodPackets = 0;
    
    printf("number of data packets: %d\n", (unsigned int)*ioNumberDataPackets);
    
    for (int i = 0; i < *ioNumberDataPackets; i++) {
        buffer = TPCircularBufferTail(&myInfo->cBuffer, &spaceAvailableInBuffer);
        if (spaceAvailableInBuffer == 0) {
            return -1;
        }
        printf("Space in the buffer: %d at %d\n", spaceAvailableInBuffer, buffer);
        printf("Space larger than AudioStreamPacketDescription: %lu\n", sizeof(AudioStreamPacketDescription) + ((AudioStreamPacketDescription*)buffer)->mDataByteSize);
        
        if (myInfo->isFormatVBR && spaceAvailableInBuffer >= sizeof(AudioStreamPacketDescription)
                                && spaceAvailableInBuffer >= sizeof(AudioStreamPacketDescription) + ((AudioStreamPacketDescription*)buffer)->mDataByteSize) {
            printf("VBR and there is enough in the buffer: %d\n", spaceAvailableInBuffer);
            memcpy(myInfo->aspds + i, buffer, sizeof(AudioStreamPacketDescription));
            
            ioData->mBuffers[0].mDataByteSize = (myInfo->aspds + i)->mDataByteSize;
            myInfo->audioData = malloc(ioData->mBuffers[0].mDataByteSize);
            
            memcpy(myInfo->audioData, buffer, ioData->mBuffers[0].mDataByteSize);
            ioData->mBuffers[0].mData = myInfo->audioData;
            
            TPCircularBufferConsume(&myInfo->cBuffer, sizeof(AudioStreamPacketDescription) + ioData->mBuffers[0].mDataByteSize);
            goodPackets++;
        }
        else if (myInfo->isFormatVBR == NO && spaceAvailableInBuffer >= myInfo->inputASBD->mBytesPerPacket) {
            printf("Not VBR but there is enough in the buffer\n");
            ioData->mBuffers[0].mDataByteSize = myInfo->inputASBD->mBytesPerPacket;
            ioData->mBuffers[0].mData = buffer;
            TPCircularBufferConsume(&myInfo->cBuffer, ioData->mBuffers[0].mDataByteSize);
            goodPackets++;
        }
        else {
            printf("not enough data in the buffer\n");
            break;
        }
    }
    *ioNumberDataPackets = goodPackets;
    *outDataPacketDescription = myInfo->aspds;
    
    if (*ioNumberDataPackets > 0) {
        return 0;
    }
    else if (*ioNumberDataPackets == 0) {
        printf("Zero packets to return\n");
        return -50;
    }
    else {
        return -3;
    }
}

- (UIImage*)getAlbumImage
{
    if (image)
        return image;
    
    if (sentRequest == NO){
        [[QPSessionManager sessionManager] requestAlbumArtwork:self];
        sentRequest = YES;
    }
    return nil;
}

@end
