//
//  LocalSong.m
//  SongTrain
//
//  Created by Quinton Petty on 4/12/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "LocalSong.h"

@implementation LocalSong {
    AudioConverterRef converter;
    
    AVAssetReader *assetReader;
    AVAssetReaderTrackOutput *assetOutput;
    
    CMSampleBufferRef sampleBuffer;
    CMBlockBufferRef blockBuffer;
    AudioStreamPacketDescription aspds[256];
    
    BOOL readyWithPackets;
    MPMediaItem *mediaItem;
}

- (instancetype)initWithItem:(MPMediaItem*)item andOutputASBD:(AudioStreamBasicDescription)audioStreanBasicDescription andPeer:(MCPeerID*)peer
{
    if(self = [self initWithTitle:[item valueForProperty:MPMediaItemPropertyTitle] andArtist:[item valueForProperty:MPMediaItemPropertyArtist] andPeer:peer])
    {
        mediaItem = item;
        self.url = [item valueForProperty:MPMediaItemPropertyAssetURL];
        self.songLength = [[item valueForProperty:MPMediaItemPropertyPlaybackDuration] intValue];
        self.persistantID = [item valueForProperty:MPMediaItemPropertyPersistentID];
        
        self.isFinishedSendingSong = readyWithPackets = NO;
        
        self.assetURL = [AVURLAsset URLAssetWithURL:self.url options:nil];
        
        CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)[[[_assetURL.tracks objectAtIndex:0] formatDescriptions] objectAtIndex:0];
        const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription (item);
        /*
         NSLog(@"ASBD sample rate: %f", asbd->mSampleRate);
         NSLog(@"ASBD format id: %d", asbd->mFormatID);
         NSLog(@"ASBD format flags: %d", asbd->mFormatFlags);
         NSLog(@"ASBD frames per packet: %d", asbd->mFramesPerPacket);
         NSLog(@"ASBD channels per frame: %d", asbd->mChannelsPerFrame);
         NSLog(@"ASBD bits per channel: %d", asbd->mBitsPerChannel);
         NSLog(@"ASBD bytes per packet: %d", asbd->mBytesPerPacket);
         NSLog(@"ASBD bytes per frame: %d", asbd->mBytesPerFrame);
         */
        memcpy(self.inputASBD, asbd, sizeof(AudioStreamBasicDescription));
        self.inputASDBIsSet = YES;
        
        memcpy(outputASBD, &audioStreanBasicDescription, sizeof(AudioStreamBasicDescription));
        
        sampleBuffer = NULL;
        blockBuffer = NULL;
        
        self.isFinishedSendingSong = NO;
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        self.persistantID = [aDecoder decodeObjectForKey:@"id"];
        MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:self.persistantID forProperty:MPMediaItemPropertyPersistentID];
        MPMediaQuery *songQuery = [[MPMediaQuery alloc] init];
        [songQuery addFilterPredicate:predicate];
        if (songQuery.items.count != 0) {
            mediaItem = songQuery.items[0];
        }
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.persistantID forKey:@"id"];
}

-(void)prepareSong {
    if (self.remoteSong) {
        [super prepareSong];
        return;
    }
    
    NSError *assetError;
    if (self.assetURL == nil) {
        self.assetURL = [AVURLAsset URLAssetWithURL:self.url options:nil];
    }
    assetReader = [AVAssetReader assetReaderWithAsset:self.assetURL error:&assetError];
    
    assetOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:self.assetURL.tracks[0] outputSettings:nil];
    if (![assetReader canAddOutput:assetOutput])
    {NSLog(@"Asset Reader instansiation error");}
    
    [assetReader addOutput:assetOutput];
    [assetReader startReading];
    
    AudioConverterNew(self.inputASBD, outputASBD, &converter);
    readyWithPackets = YES;
}

- (void)cleanUpSong{
    if (self.remoteSong) {
        [super cleanUpSong];
        return;
    }
    //NSLog(@"Cleaning up the song, trying to stop sending packets\n");
}

- (int)getMusicPackets:(UInt32*)numOfPackets forBuffer:(AudioBufferList*)ioData
{
    if (self.remoteSong) {
        return [super getMusicPackets:numOfPackets forBuffer:ioData];
    }
    
    OSStatus err = -5;
    if (readyWithPackets == YES) {
        err = AudioConverterFillComplexBuffer(converter, converterInputCallback, (__bridge void*)self, numOfPackets, ioData, NULL);
    }
    
    return err;
}

OSStatus converterInputCallback(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription  **outDataPacketDescription, void *inUserData)
{
    LocalSong *song = (__bridge LocalSong *)inUserData;
    
    if (song->sampleBuffer) {
        CFRelease(song->sampleBuffer);
    }
    if (song->blockBuffer) {
        CFRelease(song->blockBuffer);
        song->blockBuffer = NULL;
    }
    
    song->sampleBuffer = [song->assetOutput copyNextSampleBuffer];
    
    if (song->sampleBuffer == NULL) {
        NSLog(@"sample buffer is null after copyNextSampleBuffer");
        NSLog(@"error: %@", song->assetReader.error);
        return -2;
    }
    
    size_t packetDescriptionSize;
    
    *outDataPacketDescription = song->aspds;
    OSStatus err = CMSampleBufferGetAudioStreamPacketDescriptions(song->sampleBuffer, sizeof(song->aspds), song->aspds, NULL);
    
    CMSampleBufferGetAudioStreamPacketDescriptionsPtr(song->sampleBuffer, NULL, &packetDescriptionSize);
    *ioNumberDataPackets = (UInt32)packetDescriptionSize / sizeof(AudioStreamPacketDescription);
    
    if (err) {
        CFRelease(song->sampleBuffer);
        song->sampleBuffer = NULL;
        song->blockBuffer = NULL;
        return -2;
    }
    
    err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(song->sampleBuffer, NULL, ioData, sizeof(AudioBufferList), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &song->blockBuffer);
    
    if (err) {
        CFRelease(song->sampleBuffer);
        song->sampleBuffer = NULL;
        song->blockBuffer = NULL;
        return -2;
    }
    
    return 0;
}

-(NSData *)getNextPacketofMaxBytes:(NSInteger)maxBytes
{
    
    if (sampleBuffer == NULL) {
        sampleBuffer = [assetOutput copyNextSampleBuffer];
    }
    
    if (sampleBuffer == NULL || CMSampleBufferGetNumSamples(sampleBuffer) == 0) {
        if(sampleBuffer) {
            CFRelease(sampleBuffer);
            sampleBuffer = NULL;
        }
        NSLog(@"No more to stream, end of song\n");
        self.isFinishedSendingSong = YES;
        return nil;
    }
    
    AudioBufferList audioBufferList;
    const AudioStreamPacketDescription *aspd;
    size_t packetDescriptionSize;
    
    OSStatus err = CMSampleBufferGetAudioStreamPacketDescriptionsPtr(sampleBuffer, &aspd, &packetDescriptionSize);
    UInt32 numOfASPD = (UInt32)packetDescriptionSize / sizeof(AudioStreamPacketDescription);
    
    if (err) {
        CFRelease(sampleBuffer);
        return nil;
    }
    
    err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(AudioBufferList), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBuffer);
    
    if (err) {
        CFRelease(sampleBuffer);
        sampleBuffer = NULL;
        return nil;
    }
    
    NSUInteger buffSize = packetDescriptionSize;
    
    for (NSUInteger i = 0; i < audioBufferList.mNumberBuffers; i++) {
        AudioBuffer audioBuffer = audioBufferList.mBuffers[i];
        buffSize += audioBuffer.mDataByteSize;
    }
    
    if (buffSize > maxBytes) {
        CFRelease(blockBuffer);
        blockBuffer = NULL;
        return nil;
    }
    
    uint8_t *totalBuffer = malloc(buffSize);
    size_t offset = 0;
    
    for (NSUInteger i = 0; i < numOfASPD; i++) {
        memcpy(totalBuffer + offset, &aspd[i], sizeof(AudioStreamPacketDescription));
        offset += sizeof(AudioStreamPacketDescription);
        memcpy(totalBuffer + offset, audioBufferList.mBuffers[0].mData + aspd[i].mStartOffset, aspd[i].mDataByteSize);
        offset += aspd[i].mDataByteSize;
    }
    
    NSData *bufferData = [NSData dataWithBytesNoCopy:totalBuffer length:offset freeWhenDone:YES];
    
    CFRelease(blockBuffer);
    CFRelease(sampleBuffer);
    sampleBuffer = NULL;
    blockBuffer = NULL;
    
    return bufferData;
}


- (UIImage*)getAlbumImage
{
    //NSLog(@"updating picture, remoteSong: %@", self.remoteSong ? @"YES" : @"NO");
    if (self.remoteSong) {
        return [super getAlbumImage];
    }
    
    if (image)
        return image;
    
    MPMediaItemArtwork *albumItem = [mediaItem valueForProperty:MPMediaItemPropertyArtwork];
    if (albumItem) {
        image = [albumItem imageWithSize:CGSizeMake(PICTURE_HEIGHT_AND_WIDTH, PICTURE_HEIGHT_AND_WIDTH)];
        return image;
    }
    else {
        NSLog(@"No Current Image\n");
        return nil;
    }
}

-(void)dealloc {
    assetReader = nil;
    assetOutput = nil;
    mediaItem = nil;
    AudioConverterDispose(converter);
    
    if (sampleBuffer) {
        CFRelease(sampleBuffer);
    }
    if (blockBuffer) {
        CFRelease(blockBuffer);
    }
}

@end
