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
}

- (instancetype)initWithOutputASBD:(AudioStreamBasicDescription)audioStreamBD andItem:(MPMediaItem*)item {
    if (self = [super initWithOutputASBD:audioStreamBD]) {
        self.title = [item valueForProperty:MPMediaItemPropertyTitle];
        self.artistName = [item valueForProperty:MPMediaItemPropertyArtist];
        self.url = [item valueForProperty:MPMediaItemPropertyAssetURL];
        self.songLength = [[item valueForProperty:MPMediaItemPropertyPlaybackDuration] intValue];
        
        sampleBuffer = NULL;
        blockBuffer = NULL;
        
        assetURL = [AVURLAsset URLAssetWithURL:self.url options:nil];
        NSError *assetError;
        assetReader = [AVAssetReader assetReaderWithAsset:assetURL error:&assetError];
        
        CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)[[[assetURL.tracks objectAtIndex:0] formatDescriptions] objectAtIndex:0];
        const AudioStreamBasicDescription* bobTheDesc = CMAudioFormatDescriptionGetStreamBasicDescription (item);
        
        memcpy(inputASBD, bobTheDesc, sizeof(AudioStreamBasicDescription));
        
        assetOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetURL.tracks[0] outputSettings:nil];
        if (![assetReader canAddOutput:assetOutput])
        {NSLog(@"Asset Reader instansiation error");}
        
        [assetReader addOutput:assetOutput];
        [assetReader startReading];
        
        AudioConverterNew(inputASBD, outputASBD, &converter);
    }
    return self;
}

- (int)getMusicPackets:(UInt32*)numOfPackets forBuffer:(AudioBufferList*)ioData
{
    //printf("get packets");
    //return AudioConverterFillComplexBuffer(converter, converterInputCallback, (__bridge void *)(self), &numOfPackets, ioData, nil);
    //LocalSong *audioPlayback = (__bridge LocalSong *)object;
    OSStatus err = AudioConverterFillComplexBuffer(converter, converterInputCallback, (__bridge void*)self, numOfPackets, ioData, NULL);
    NSLog(@"Number of out Packets: %u\n", *numOfPackets);
    return err;
}

OSStatus converterInputCallback(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription  **outDataPacketDescription, void *inUserData)
{
    LocalSong *song = (__bridge LocalSong *)inUserData;
    
    //CMSampleBufferRef sampleBuffer;
    
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
    
    
    //CMBlockBufferRef blockBuffer;
    //AudioBufferList audioBufferList;
    //const AudioStreamPacketDescription *aspd = *outDataPacketDescription;
    size_t packetDescriptionSize;
    
    //OSStatus err = CMSampleBufferGetAudioStreamPacketDescriptionsPtr(song->sampleBuffer, &aspd, &packetDescriptionSize);
    
    *outDataPacketDescription = song->aspds;
    OSStatus err = CMSampleBufferGetAudioStreamPacketDescriptions(song->sampleBuffer, sizeof(song->aspds), song->aspds, NULL);
    
    CMSampleBufferGetAudioStreamPacketDescriptionsPtr(song->sampleBuffer, NULL, &packetDescriptionSize);
    *ioNumberDataPackets = packetDescriptionSize / sizeof(AudioStreamPacketDescription);
    
    //printf("number: %d\n", *ioNumberDataPackets);
    //*ioNumberDataPackets = packetDescriptionSize / sizeof(AudioStreamPacketDescription);
    
    if (err) {
        CFRelease(song->sampleBuffer);
        song->sampleBuffer = NULL;
        song->blockBuffer = NULL;
        return -2;
    }
    
    //[self.audioStream writeData:(uint8_t*)&numOfASPD maxLength:sizeof(UInt32)];
    //[self.audioStream writeData:(uint8_t*)aspd maxLength:packetDescriptionSize];
    
    //NSLog(@"Size: %zu, each packetdescription is %lu\n", packetDescriptionSize, sizeof(AudioStreamPacketDescription));
    
    err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(song->sampleBuffer, NULL, ioData, sizeof(AudioBufferList), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &song->blockBuffer);
    
    if (err) {
        CFRelease(song->sampleBuffer);
        song->sampleBuffer = NULL;
        song->blockBuffer = NULL;
        return -2;
    }
    
    return 0;
}

@end
