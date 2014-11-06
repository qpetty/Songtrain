//
//  RemoteSong.m
//  SongTrain
//
//  Created by Quinton Petty on 5/2/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "RemoteSong.h"

@implementation RemoteSong {
    BOOL sentRequest, musicRequestSent;
    BOOL stillStreaming, isFormatVBR;
    
    TPCircularBuffer cBuffer;
    AudioConverterRef converter;
    AudioStreamPacketDescription aspds[256];
    uint8_t *audioData;
    
    NSTimer *packetTimer;
}

- (instancetype)initWithSong:(Song*)song ofType:(RemoteSongType)type fromPeer:(MCPeerID*)peer andOutputASBD:(AudioStreamBasicDescription)audioStreamBD
{
    if (self = [super initWithSong:song andOutputASBD:audioStreamBD]) {
        self.type = type;
        self.peer = peer;
        [self initHelp];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.peer = [coder decodeObjectForKey:@"peer"];
        self.type = [coder decodeIntegerForKey:@"type"];
        [self initHelp];
    }
    return self;
}

- (void)initHelp {
    image = nil;
    sentRequest = musicRequestSent = NO;
    cBuffer.buffer = NULL;
    converter = NULL;
    packetTimer = nil;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:self.peer forKey:@"peer"];
    [coder encodeInteger:self.type forKey:@"type"];
}

- (void)initConverter {
    if (self.inputASDBIsSet && converter == NULL) {
        OSStatus err = AudioConverterNew(self.inputASBD, outputASBD, &converter);
        NSLog(@"Initing COnverter!!!!!!!!!");
        isFormatVBR = (self.inputASBD->mBytesPerPacket == 0 || self.inputASBD->mFramesPerPacket == 0);
        if (err) {
            NSLog(@"found status '%c%c%c%c'\n", (char)(err>>24)&255, (char)(err>>16)&255, (char)(err>>8)&255, (char)err&255);
        }
    }
}

- (void)prepareSong{
    [[QPSessionManager sessionManager] prepareRemoteSong:self];
    TPCircularBufferInit(&cBuffer, kBufferLength);
    
    audioData = NULL;
    [self askForPacket];
    [self initConverter];
}

- (void)timerIsFinished {
    [packetTimer invalidate];
    packetTimer = nil;
    [self askForPacket];
}

- (void)askForPacket {
    dispatch_async(dispatch_get_main_queue(), ^{
        
    NSLog(@"Asking for more data to get the converter going for: %@", self.title);
    
    if (musicRequestSent == NO && cBuffer.fillCount < 3 * kBufferLength / 4 && self.isFinishedSendingSong == NO && packetTimer == nil) {
        musicRequestSent = YES;
        
        NSLog(@"sending");
        [[QPSessionManager sessionManager] requestMusicDataForSong:self withAvailableBytes:kBufferLength - cBuffer.fillCount];
        
        //Might use to allow sometime between packet requests
        packetTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timerIsFinished) userInfo:nil repeats:YES];
    }
        
    });
}

- (void)submitBytes:(NSData*)bytes
{
    NSLog(@"Got %lu bytes here in remote song: %@", bytes.length, self.title);
    if (bytes.length == 0) {
        musicRequestSent = NO;
        [self askForPacket];
    } else {
        [self timerIsFinished];
        TPCircularBufferProduceBytes(&(cBuffer), bytes.bytes, (uint32_t)bytes.length);
    }
}

- (int)getMusicPackets:(UInt32*)numOfPackets forBuffer:(AudioBufferList*)ioData
{
    OSStatus err = -5;
    if (self.inputASDBIsSet == YES) {
        [self initConverter];
        
        if (cBuffer.fillCount == 0 && self.isFinishedSendingSong) {
            return -2;
        }
        
        if (cBuffer.fillCount < kBufferLength / 4) {
            //Send music request and start timer;
            [self askForPacket];
        }
        
        err = AudioConverterFillComplexBuffer(converter, converterCallback, (__bridge void*)self, numOfPackets, ioData, NULL);
        //NSLog(@"Number of out Packets: %u\n", *numOfPackets);
    }
    
    return err;
}

OSStatus converterCallback(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription  **outDataPacketDescription, void *inUserData)
{
    RemoteSong *myInfo = (__bridge RemoteSong *)inUserData;
    
    int32_t availableBytes;
    uint8_t *buffer;
    int goodPackets = 0;
    
    //printf("timer %d\n", myInfo->timer);
    //printf("number of data packets: %d\n", (unsigned int)*ioNumberDataPackets);
    
    for (int i = 0; i < *ioNumberDataPackets; i++) {
        buffer = TPCircularBufferTail(&myInfo->cBuffer, &availableBytes);
        
        //printf("Space in the buffer: %d at %d\n", spaceAvailableInBuffer, buffer);
        //printf("Space larger than AudioStreamPacketDescription: %lu\n", sizeof(AudioStreamPacketDescription) + ((AudioStreamPacketDescription*)buffer)->mDataByteSize);
        
        if (myInfo->isFormatVBR && availableBytes >= sizeof(AudioStreamPacketDescription)
                                && availableBytes >= sizeof(AudioStreamPacketDescription) + ((AudioStreamPacketDescription*)buffer)->mDataByteSize) {
            //printf("VBR and there is enough in the buffer: %d\n", availableBytes);
            memcpy(myInfo->aspds + i, buffer, sizeof(AudioStreamPacketDescription));
            
            (myInfo->aspds + i)->mStartOffset = 0;
            ioData->mBuffers[0].mDataByteSize = (myInfo->aspds + i)->mDataByteSize;
            ioData->mBuffers[0].mNumberChannels = myInfo.inputASBD->mChannelsPerFrame;
            //printf("Data Size: %d Total size: %lu\n",(unsigned int)ioData->mBuffers[0].mDataByteSize, ioData->mBuffers[0].mDataByteSize + sizeof(AudioStreamPacketDescription));
            
            //TODO: Memory leak?
            if (myInfo->audioData) {
                free(myInfo->audioData);
                myInfo->audioData = NULL;
            }
            myInfo->audioData = malloc(ioData->mBuffers[0].mDataByteSize);
            
            memcpy(myInfo->audioData, buffer + sizeof(AudioStreamPacketDescription), ioData->mBuffers[0].mDataByteSize);
            ioData->mBuffers[0].mData = myInfo->audioData;
            
            TPCircularBufferConsume(&myInfo->cBuffer, sizeof(AudioStreamPacketDescription) + ioData->mBuffers[0].mDataByteSize);
            goodPackets++;
        }
        else if (myInfo->isFormatVBR == NO && availableBytes >= myInfo.inputASBD->mBytesPerPacket) {
            printf("Not VBR but there is enough in the buffer\n");
            ioData->mBuffers[0].mDataByteSize = myInfo.inputASBD->mBytesPerPacket;
            ioData->mBuffers[0].mNumberChannels = myInfo.inputASBD->mChannelsPerFrame;
            ioData->mBuffers[0].mData = buffer;
            TPCircularBufferConsume(&myInfo->cBuffer, ioData->mBuffers[0].mDataByteSize);
            goodPackets++;
        }
        else {
            /*
            if (myInfo->isFormatVBR && spaceAvailableInBuffer >= sizeof(AudioStreamPacketDescription)) {
                NSLog(@"VBR and found %lu bytes\n", sizeof(AudioStreamPacketDescription) + ((AudioStreamPacketDescription*)buffer)->mDataByteSize);
            }
            if (spaceAvailableInBuffer >= sizeof(AudioStreamPacketDescription)) {
                NSLog(@"Found %lu bytes\n", sizeof(AudioStreamPacketDescription) + ((AudioStreamPacketDescription*)buffer)->mDataByteSize);
            }
             */
            printf("not enough data in the buffer: %d\n", availableBytes);
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

- (void)cleanUpSong{
    stillStreaming = NO;
}

-(void)dealloc {
    if (cBuffer.buffer != NULL) {
        TPCircularBufferCleanup(&cBuffer);
    }
    AudioConverterDispose(converter);
    if (audioData) {
        free(audioData);
        audioData = NULL;
    }
    
    if (packetTimer) {
        [packetTimer invalidate];
        packetTimer = nil;
    }
}

@end
