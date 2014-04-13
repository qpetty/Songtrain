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
}

- (instancetype)initWithOutputASBD:(AudioStreamBasicDescription)audioStreamBD andItem:(MPMediaItem*)item {
    if (self = [super initWithOutputASBD:audioStreamBD]) {
        self.title = [item valueForProperty:MPMediaItemPropertyTitle];
        self.artistName = [item valueForProperty:MPMediaItemPropertyArtist];
        self.url = [item valueForProperty:MPMediaItemPropertyAssetURL];
        
        assetURL = [AVURLAsset URLAssetWithURL:self.url options:nil];
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

- (int)getMusicPackets:(UInt32)numOfPackets forBuffer:(AudioBufferList*)ioData
{
    return AudioConverterFillComplexBuffer(converter, converterInputCallback, (__bridge void *)(self), &numOfPackets, ioData, nil);
}

OSStatus converterInputCallback(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription  **outDataPacketDescription, void *inUserData)
{
    LocalSong *audioPlayback = (__bridge LocalSong *)inUserData;
    
    CMSampleBufferRef sampleBuffer;
    
    sampleBuffer = [audioPlayback->assetOutput copyNextSampleBuffer];
    
    if (sampleBuffer == NULL || CMSampleBufferGetNumSamples(sampleBuffer) == 0) {
        CFRelease(sampleBuffer);
        return -1;
    }
    
    CMBlockBufferRef blockBuffer;
    //AudioBufferList audioBufferList;
    const AudioStreamPacketDescription *aspd = *outDataPacketDescription;
    size_t packetDescriptionSize;
    
    OSStatus err = CMSampleBufferGetAudioStreamPacketDescriptionsPtr(sampleBuffer, &aspd, &packetDescriptionSize);
    
    if (err) {
        CFRelease(sampleBuffer);
        return -1;
    }
    
    //[self.audioStream writeData:(uint8_t*)&numOfASPD maxLength:sizeof(UInt32)];
    //[self.audioStream writeData:(uint8_t*)aspd maxLength:packetDescriptionSize];
    
    //NSLog(@"Size: %zu, each packetdescription is %lu\n", packetDescriptionSize, sizeof(AudioStreamPacketDescription));
    
    err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, ioData, sizeof(AudioBufferList), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBuffer);
    
    if (err) {
        CFRelease(sampleBuffer);
        return -1;
    }

    CFRelease(blockBuffer);
    CFRelease(sampleBuffer);
    
    return 0;
}

@end
