//
//  LocalSong.m
//  SongTrain
//
//  Created by Quinton Petty on 4/12/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "LocalSong.h"

@implementation LocalSong{
    AudioConverterRef converter;
    
    AVAssetReader *assetReader;
    AVAssetReaderTrackOutput *assetOutput;
    
    CMSampleBufferRef sampleBuffer;
    CMBlockBufferRef blockBuffer;
    AudioStreamPacketDescription aspds[256];
    
    MPMediaItem *mediaItem;
    
}

- (instancetype)initLocalSongFromSong:(Song*)song WithOutputASBD:(AudioStreamBasicDescription)audioStreamBD
{
    MPMediaQuery *query = [MPMediaQuery songsQuery];
    [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:song.persistantID forProperty:MPMediaItemPropertyPersistentID]];
    NSArray *displayItems = [query items];
    
    self.isFinishedSendingSong = NO;
    mediaItem = [displayItems firstObject];
    
    if (mediaItem)
        return [[LocalSong alloc] initWithOutputASBD:audioStreamBD andItem:mediaItem];
    else
        return nil;
}

- (instancetype)initWithOutputASBD:(AudioStreamBasicDescription)audioStreamBD andItem:(MPMediaItem*)item {
    if (self = [super initWithItem:item andOutputASBD:audioStreamBD]) {
        mediaItem = item;
        
        sampleBuffer = NULL;
        blockBuffer = NULL;

        self.isFinishedSendingSong = NO;
        
        NSError *assetError;
        assetReader = [AVAssetReader assetReaderWithAsset:self.assetURL error:&assetError];
        
        assetOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:self.assetURL.tracks[0] outputSettings:nil];
        if (![assetReader canAddOutput:assetOutput])
        {NSLog(@"Asset Reader instansiation error");}
        
        [assetReader addOutput:assetOutput];
        [assetReader startReading];
        
        AudioConverterNew(self.inputASBD, outputASBD, &converter);
    }
    return self;
}

- (void)cleanUpSong{
    //NSLog(@"Cleaning up the song, trying to stop sending packets\n");

}

- (void)unScheduleStream
{

}

- (int)getMusicPackets:(UInt32*)numOfPackets forBuffer:(AudioBufferList*)ioData
{
    OSStatus err = AudioConverterFillComplexBuffer(converter, converterInputCallback, (__bridge void*)self, numOfPackets, ioData, NULL);
    //NSLog(@"Number of out Packets: %u\n", *numOfPackets);
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
    }
    
    song->sampleBuffer = [song->assetOutput copyNextSampleBuffer];
    
    if (song->sampleBuffer == NULL || CMSampleBufferGetNumSamples(song->sampleBuffer) == 0) {
        if (song->sampleBuffer)
            CFRelease(song->sampleBuffer);
        song->sampleBuffer = NULL;
        song->blockBuffer = NULL;
        return -2;
    }
    
    size_t packetDescriptionSize;
    
    *outDataPacketDescription = song->aspds;
    OSStatus err = CMSampleBufferGetAudioStreamPacketDescriptions(song->sampleBuffer, sizeof(song->aspds), song->aspds, NULL);
    
    CMSampleBufferGetAudioStreamPacketDescriptionsPtr(song->sampleBuffer, NULL, &packetDescriptionSize);
    *ioNumberDataPackets = packetDescriptionSize / sizeof(AudioStreamPacketDescription);
    
    //printf("number: %d\n", *ioNumberDataPackets);
    
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
        sampleBuffer = NULL;
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
    
    return bufferData;
}


- (UIImage*)getAlbumImage
{
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

@end
