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
    AVURLAsset *assetURL;
    AVAssetReaderTrackOutput *assetOutput;
    AVAssetReader *assetReader;
    
    CMSampleBufferRef sampleBuffer;
    CMBlockBufferRef blockBuffer;
    AudioStreamPacketDescription aspds[256];
    
    MPMediaItem *mediaItem;
    
    NSThread *streamingThread;
}

- (instancetype)initLocalSongFromSong:(Song*)song WithOutputASBD:(AudioStreamBasicDescription)audioStreamBD
{
    MPMediaQuery *query = [MPMediaQuery songsQuery];
    [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:song.persistantID forProperty:MPMediaItemPropertyPersistentID]];
    NSArray *displayItems = [query items];
    
    mediaItem = [displayItems firstObject];
    
    if (mediaItem)
        return [[LocalSong alloc] initWithOutputASBD:audioStreamBD andItem:mediaItem];
    else
        return nil;
}

- (instancetype)initWithOutputASBD:(AudioStreamBasicDescription)audioStreamBD andItem:(MPMediaItem*)item {
    if (self = [super initWithOutputASBD:audioStreamBD]) {
        self.title = [item valueForProperty:MPMediaItemPropertyTitle];
        self.artistName = [item valueForProperty:MPMediaItemPropertyArtist];
        self.persistantID = [item valueForProperty:MPMediaItemPropertyPersistentID];
        self.url = [item valueForProperty:MPMediaItemPropertyAssetURL];
        self.songLength = [[item valueForProperty:MPMediaItemPropertyPlaybackDuration] intValue];
        
        image = nil;
        
        mediaItem = item;
        
        sampleBuffer = NULL;
        blockBuffer = NULL;
        
        assetURL = [AVURLAsset URLAssetWithURL:self.url options:nil];
        NSError *assetError;
        assetReader = [AVAssetReader assetReaderWithAsset:assetURL error:&assetError];
        
        CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)[[[assetURL.tracks objectAtIndex:0] formatDescriptions] objectAtIndex:0];
        const AudioStreamBasicDescription* bobTheDesc = CMAudioFormatDescriptionGetStreamBasicDescription (item);
        
        memcpy(self->inputASBD, bobTheDesc, sizeof(AudioStreamBasicDescription));
        
        assetOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetURL.tracks[0] outputSettings:nil];
        if (![assetReader canAddOutput:assetOutput])
        {NSLog(@"Asset Reader instansiation error");}
        
        [assetReader addOutput:assetOutput];
        [assetReader startReading];
        
        AudioConverterNew(self->inputASBD, outputASBD, &converter);
    }
    return self;
}

- (void)startStreaming
{
    NSLog(@"Start Streaming\n");
    if (!self.outStream) {
        NSLog(@"No Outputstream to write to\n");
        return;
    }
    self.outStream.delegate = self;
    if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        return [self performSelectorOnMainThread:@selector(startStreaming) withObject:nil waitUntilDone:YES];
    }
    
    streamingThread = [[NSThread alloc] initWithTarget:self selector:@selector(startThread) object:nil];
    [streamingThread start];
}

- (void)startThread
{
    [self.outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.outStream open];
    while ([[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ;
}

-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    if (eventCode == NSStreamEventHasSpaceAvailable) {
        [self sendDataChunk];
    }
    else if (eventCode == NSStreamEventEndEncountered) {
        //close loop
    }
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

- (void)sendDataChunk
{
    sampleBuffer = [assetOutput copyNextSampleBuffer];
    
    if (sampleBuffer == NULL || CMSampleBufferGetNumSamples(sampleBuffer) == 0) {
        CFRelease(sampleBuffer);
        return;
    }
    
    AudioBufferList audioBufferList;
    
    OSStatus err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(AudioBufferList), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBuffer);
    
    if (err) {
        CFRelease(sampleBuffer);
        return;
    }
    
    for (NSUInteger i = 0; i < audioBufferList.mNumberBuffers; i++) {
        AudioBuffer audioBuffer = audioBufferList.mBuffers[i];
        NSInteger size = [self.outStream write:audioBuffer.mData maxLength:audioBuffer.mDataByteSize];
        NSLog(@"wrote %u of buffer size: %u", size, (unsigned int)audioBuffer.mDataByteSize);
    }
    
    CFRelease(blockBuffer);
    CFRelease(sampleBuffer);
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

-(void)dealloc{
    NSLog(@"deallocate stuff from %@\n", self.title);
    [self.outStream close];
}

@end
