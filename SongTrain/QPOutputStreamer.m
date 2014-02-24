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
    output = outputStream;
    output.delegate = self;
    
    assestURL = url;
    
    if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        return [self performSelectorOnMainThread:@selector(makeThread) withObject:nil waitUntilDone:YES];
    }
    
    [self makeThread];
}

- (void)makeThread
{
    NSLog(@"Allocating and starting music thread\n");
    musicThread = [[NSThread alloc] initWithTarget:self selector:@selector(start) object:nil];
    [musicThread start];
}

- (void)start
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:assestURL options:nil];
    NSError *assetError;
    
    assetReader = [AVAssetReader assetReaderWithAsset:asset error:&assetError];
    assetOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:asset.tracks[0] outputSettings:nil];
    if (![assetReader canAddOutput:assetOutput]){
        NSLog(@"Can't add asset output\n");
        return;
    }
    
    [assetReader addOutput:assetOutput];
    [assetReader startReading];
    NSLog(@"Read Asset");
    
    CMSampleBufferRef sampleBuffer;
    sampleBuffer = [assetOutput copyNextSampleBuffer];
    
    if (!(blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer))) {
        NSLog(@"Could not get data Buffer\n");
    }
    
    CFRetain(blockBuffer);
    
    totalBytes = CMBlockBufferGetDataLength(blockBuffer);
    NSLog(@"Data Size: %lu\n", totalBytes);
    currentByte = 0;
    
    CFRelease(sampleBuffer);
    
    [output scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [output open];
    
    while (1 && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    if (eventCode == NSStreamEventOpenCompleted) {
        NSLog(@"Output Stream opened\n");
    }
    else if (eventCode == NSStreamEventHasSpaceAvailable){
        NSLog(@"Give stream some bytes\n");
        [self sendDataChunk:(NSOutputStream*)aStream];
    }
}

- (void)sendDataChunk:(NSOutputStream*)outputStream
{
    uint8_t buffer[2000];
    char *ptr;
    
    NSLog(@"Accessing bytes %lu - %lu\n", currentByte, currentByte + sizeof(buffer));
    if(CMBlockBufferAccessDataBytes(blockBuffer, currentByte, sizeof(buffer), buffer, &ptr) != kCMBlockBufferNoErr){
        NSLog(@"Could not access data in blockbuffer\n");
        return;
    }
    NSInteger writenSize = [outputStream write:(uint8_t*)ptr maxLength:sizeof(buffer)];
    NSLog(@"Wrote %ld bytes to outtStream\n", (long)writenSize);
    currentByte += writenSize;
}

@end
