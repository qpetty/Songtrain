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
    
    BOOL stillStreaming, isFormatVBR;
    
    TPCircularBuffer cBuffer;
    AudioConverterRef converter;
    AudioStreamPacketDescription aspds[256];
    uint8_t *audioData;
}

- (instancetype)initWithSong:(Song*)song fromPeer:(MCPeerID*)peer andOutputASBD:(AudioStreamBasicDescription)audioStreamBD
{
    if (self = [super initWithSong:song andOutputASBD:audioStreamBD]) {
        self.peer = peer;
        
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
    OSStatus err = AudioConverterNew(self.inputASBD, outputASBD, &converter);
    isFormatVBR = (self.inputASBD->mBytesPerPacket == 0 || self.inputASBD->mFramesPerPacket == 0);
    if (err) {
        NSLog(@"found status '%c%c%c%c'\n", (char)(err>>24)&255, (char)(err>>16)&255, (char)(err>>8)&255, (char)err&255);
    }
}


- (void)submitBytes:(NSData*)bytes
{
    TPCircularBufferProduceBytes(&(cBuffer), bytes.bytes, (uint32_t)bytes.length);
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
    
    //printf("number of data packets: %d\n", (unsigned int)*ioNumberDataPackets);
    
    for (int i = 0; i < *ioNumberDataPackets; i++) {
        buffer = TPCircularBufferTail(&myInfo->cBuffer, &spaceAvailableInBuffer);
        if (spaceAvailableInBuffer == 0) {
            return -1;
        }
        //printf("Space in the buffer: %d at %d\n", spaceAvailableInBuffer, buffer);
        //printf("Space larger than AudioStreamPacketDescription: %lu\n", sizeof(AudioStreamPacketDescription) + ((AudioStreamPacketDescription*)buffer)->mDataByteSize);
        
        if (myInfo->isFormatVBR && spaceAvailableInBuffer >= sizeof(AudioStreamPacketDescription)
                                && spaceAvailableInBuffer >= sizeof(AudioStreamPacketDescription) + ((AudioStreamPacketDescription*)buffer)->mDataByteSize) {
            printf("VBR and there is enough in the buffer: %d\n", spaceAvailableInBuffer);
            memcpy(myInfo->aspds + i, buffer, sizeof(AudioStreamPacketDescription));
            
            (myInfo->aspds + i)->mStartOffset = 0;
            ioData->mBuffers[0].mDataByteSize = (myInfo->aspds + i)->mDataByteSize;
            printf("Data Size: %d Total size: %lu\n",(unsigned int)ioData->mBuffers[0].mDataByteSize, ioData->mBuffers[0].mDataByteSize + sizeof(AudioStreamPacketDescription));
            myInfo->audioData = malloc(ioData->mBuffers[0].mDataByteSize);
            
            memcpy(myInfo->audioData, buffer + sizeof(AudioStreamPacketDescription), ioData->mBuffers[0].mDataByteSize);
            ioData->mBuffers[0].mData = myInfo->audioData;
            
            TPCircularBufferConsume(&myInfo->cBuffer, sizeof(AudioStreamPacketDescription) + ioData->mBuffers[0].mDataByteSize);
            goodPackets++;
        }
        else if (myInfo->isFormatVBR == NO && spaceAvailableInBuffer >= myInfo.inputASBD->mBytesPerPacket) {
            printf("Not VBR but there is enough in the buffer\n");
            ioData->mBuffers[0].mDataByteSize = myInfo.inputASBD->mBytesPerPacket;
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
            printf("not enough data in the buffer: %d\n", spaceAvailableInBuffer);
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

@end
