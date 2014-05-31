//
//  QPOutputStreamer.m
//  SongTrain
//
//  Created by Quinton Petty on 2/24/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "QPOutputStreamer.h"

@implementation QPOutputStreamer{
    
    NSOutputStream *output;
    NSURL *assestURL;
    NSThread *musicThread;
    
    AVAssetReader *assetReader;
    AVAssetReaderTrackOutput *assetOutput;
    
    CMBlockBufferRef blockBuffer;
    size_t totalBytes;
    size_t currentByte;
}



- (void)setOutputStream:(NSOutputStream*)outputStream withURL:(NSURL *)url
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSError *assetError;
    
    output = outputStream;
    output.delegate = self;
    
    assetReader = [AVAssetReader assetReaderWithAsset:asset error:&assetError];
    
    AVAssetTrack* songTrack = [asset.tracks objectAtIndex:0];
    NSArray* formatDesc = songTrack.formatDescriptions;
    
    NSLog(@"Number of Tracks: %lu\n", (unsigned long)[asset.tracks count]);
    NSLog(@"Number of Format Descriptions: %lu\n", (unsigned long)[formatDesc count]);
    
    CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:0];
    const AudioStreamBasicDescription* bobTheDesc = CMAudioFormatDescriptionGetStreamBasicDescription (item);
    NSLog(@"ASBD Sample Rate: %lf\n",bobTheDesc->mSampleRate);
    NSLog(@"     Format ID: %8x\n",(unsigned int)bobTheDesc->mFormatID);
    NSLog(@"     Format Flags: %u\n",(unsigned int)bobTheDesc->mFormatFlags);
    NSLog(@"     Bytes per Packet: %u\n",(unsigned int)bobTheDesc->mBytesPerPacket);
    NSLog(@"     Frames per Packet: %u\n",(unsigned int)bobTheDesc->mFramesPerPacket);
    NSLog(@"     Bytes per Frame: %u\n",(unsigned int)bobTheDesc->mBytesPerFrame);
    NSLog(@"     Channels per Frame: %u\n",(unsigned int)bobTheDesc->mChannelsPerFrame);
    NSLog(@"     Bits per Channel: %u\n",(unsigned int)bobTheDesc->mBitsPerChannel);
    
    
    /*
     AudioChannelLayout channelLayout;
     memset(&channelLayout, 0, sizeof(AudioChannelLayout));
     channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
     
     
     NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
     [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
     [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
     [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)],
     AVChannelLayoutKey,
     [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
     [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
     [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
     [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
     nil];
     */
    assetOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:asset.tracks[0] outputSettings:nil];
    if (![assetReader canAddOutput:assetOutput]) return;
    
    [assetReader addOutput:assetOutput];
    [assetReader startReading];
    NSLog(@"Read Asset");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [output scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [output open];
    });
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    if (eventCode == NSStreamEventHasSpaceAvailable){
        [self sendDataChunk];
    }
}

/*
 1. Number of AudioStreamPacketDescriptions
 2. AudioStreamPacketDescriptions
 3. Size of Audio Data
 4. Audio Data
 */

- (void)sendDataChunk
{
    CMSampleBufferRef sampleBuffer;
    
    sampleBuffer = [assetOutput copyNextSampleBuffer];
    
    if (sampleBuffer == NULL || CMSampleBufferGetNumSamples(sampleBuffer) == 0) {
        CFRelease(sampleBuffer);
        return;
    }
    
    CMBlockBufferRef blockBuffer;
    AudioBufferList audioBufferList;
    const AudioStreamPacketDescription *aspd;
    size_t packetDescriptionSize;
    
    OSStatus err = CMSampleBufferGetAudioStreamPacketDescriptionsPtr(sampleBuffer, &aspd, &packetDescriptionSize);
    UInt32 numOfASPD = packetDescriptionSize / sizeof(AudioStreamPacketDescription);
    
    if (err) {
        CFRelease(sampleBuffer);
        return;
    }
    
    //[self.audioStream writeData:(uint8_t*)&numOfASPD maxLength:sizeof(UInt32)];
    //[self.audioStream writeData:(uint8_t*)aspd maxLength:packetDescriptionSize];
    
    //NSLog(@"Size: %zu, each packetdescription is %lu\n", packetDescriptionSize, sizeof(AudioStreamPacketDescription));
    
    err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(AudioBufferList), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBuffer);
    
    if (err) {
        CFRelease(sampleBuffer);
        return;
    }
    
    NSLog(@"Number of ASPDs: %d    Number of Buffers: %d\n", numOfASPD, audioBufferList.mNumberBuffers);
    
    NSUInteger dataIndex = 0;
    NSUInteger i;
    for (i = 0; i < numOfASPD; i++)
    {
        [output write:(uint8_t*)(aspd + i) maxLength:sizeof(AudioStreamPacketDescription)];
        [output write:(uint8_t*)(audioBufferList.mBuffers[0].mData + dataIndex) maxLength:(aspd + i)->mDataByteSize];
        dataIndex += (aspd + i)->mDataByteSize;
    }
    
    //NSLog(@"Audiobufferlist size: %d   dataIndex: %d\n", (unsigned int)audioBufferList.mBuffers[0].mDataByteSize, dataIndex);
    //NSLog(@"ASPD: %d    ASPD + i: %d\n", aspd, aspd + i);
    
    /*
     
     UInt32 audioSize = 0;
     for (NSUInteger i = 0; i < audioBufferList.mNumberBuffers; i++) {
     AudioBuffer audioBuffer = audioBufferList.mBuffers[i];
     audioSize += audioBuffer.mDataByteSize;
     }
     [self.audioStream writeData:(uint8_t*)&audioSize maxLength:sizeof(audioSize)];
     
     for (NSUInteger i = 0; i < audioBufferList.mNumberBuffers; i++) {
     AudioBuffer audioBuffer = audioBufferList.mBuffers[i];
     [self.audioStream writeData:audioBuffer.mData maxLength:audioBuffer.mDataByteSize];
     NSLog(@"buffer size: %u", (unsigned int)audioBuffer.mDataByteSize);
     }
     
     */
    CFRelease(blockBuffer);
    CFRelease(sampleBuffer);
}
@end
