//
//  TDAudioOutputStreamer.m
//  TDAudioStreamer
//
//  Created by Tony DiPasquale on 11/14/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <AVFoundation/AVFoundation.h>
#import "TDAudioOutputStreamer.h"
#import "TDAudioStream.h"

@interface TDAudioOutputStreamer () <TDAudioStreamDelegate>

@property (strong, nonatomic) TDAudioStream *audioStream;
@property (strong, nonatomic) AVAssetReader *assetReader;
@property (strong, nonatomic) AVAssetReaderTrackOutput *assetOutput;
@property (strong, nonatomic) NSThread *streamThread;

@property (assign, atomic) BOOL isStreaming;

@end

@implementation TDAudioOutputStreamer

- (instancetype) initWithOutputStream:(NSOutputStream *)stream
{
    self = [super init];
    if (!self) return nil;

    self.audioStream = [[TDAudioStream alloc] initWithOutputStream:stream];
    self.audioStream.delegate = self;
    NSLog(@"Init");

    return self;
}

- (void)start
{
    if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        return [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
    }

    NSLog(@"Start");
    self.streamThread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
    [self.streamThread start];
}

- (void)run
{
    @autoreleasepool {
        [self.audioStream open];

        self.isStreaming = YES;
        NSLog(@"Loop");

        while (self.isStreaming && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ;

        NSLog(@"Done");
    }
}

- (void)streamAudioFromURL:(NSURL *)url
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSError *assetError;

    self.assetReader = [AVAssetReader assetReaderWithAsset:asset error:&assetError];
    
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
    self.assetOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:asset.tracks[0] outputSettings:nil];
    if (![self.assetReader canAddOutput:self.assetOutput]) return;

    [self.assetReader addOutput:self.assetOutput];
    [self.assetReader startReading];
    NSLog(@"Read Asset");
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

    sampleBuffer = [self.assetOutput copyNextSampleBuffer];

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
    
    [self.audioStream writeData:(uint8_t*)&numOfASPD maxLength:sizeof(UInt32)];
    [self.audioStream writeData:(uint8_t*)aspd maxLength:packetDescriptionSize];
    
    NSLog(@"Size: %zu, each packetdescription is %lu\n", packetDescriptionSize, sizeof(AudioStreamPacketDescription));
    
    err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(AudioBufferList), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBuffer);

    if (err) {
        CFRelease(sampleBuffer);
        return;
    }
    
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

    CFRelease(blockBuffer);
    CFRelease(sampleBuffer);
}

- (void)stop
{
    [self performSelector:@selector(stopThread) onThread:self.streamThread withObject:nil waitUntilDone:YES];
}

- (void)stopThread
{
    self.isStreaming = NO;
    [self.audioStream close];
    NSLog(@"Stop");
}

#pragma mark - TDAudioStreamDelegate

- (void)audioStream:(TDAudioStream *)audioStream didRaiseEvent:(TDAudioStreamEvent)event
{
    switch (event) {
        case TDAudioStreamEventWantsData:
            [self sendDataChunk];
            break;

        case TDAudioStreamEventError:
            // TODO: shit!
            NSLog(@"Stream Error");
            break;

        case TDAudioStreamEventEnd:
            // TODO: shit!
            NSLog(@"Stream Ended");
            break;

        default:
            break;
    }
}

@end
