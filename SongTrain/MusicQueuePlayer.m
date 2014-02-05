//
//  MusicQueuePlayer.m
//  SongTrain
//
//  Created by Quinton Petty on 2/4/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "MusicQueuePlayer.h"

@implementation MusicQueuePlayer


- (instancetype)initWithUrl:(NSURL *)url
{
    if (self = [super init]) {
        currentURL = url;
        [self setURL:currentURL];
    }
    return self;
}

- (void)setURL:(NSURL *)url
{

    UInt32 dataSize;
    
    NSLog(@"Attempt to open: %@", currentURL.absoluteString);
    
    if((error = AudioFileOpenURL((__bridge CFURLRef)currentURL, kAudioFileReadPermission, 0, &_myinfo.mAudioFile))){
        FormatError(errorString, error);
        NSLog(@"Error opening url: %s\n", errorString);
        return;
    }
    
    AudioFileGetPropertyInfo(_myinfo.mAudioFile, kAudioFilePropertyDataFormat, &dataSize, NULL);
    NSLog(@"Size of Data Format: %lu\n", (unsigned long)dataSize);
    
    if(AudioFileGetProperty(_myinfo.mAudioFile, kAudioFilePropertyDataFormat, &dataSize, &_myinfo.mDataFormat)){
        NSLog(@"Error getting Property\n");
        return;
    }
    
    //CAStreamBasicDescription::Print();
    
    //error = AudioQueueNewOutput (&myinfo.mDataFormat, AQTestBufferCallback, &myinfo, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &myinfo.mQueue);
    //NSLog(@"Just called queue new output with error code: %d\n", error);
    
    
    //Apple Example Code below
    
    UInt32 maxPacketSize;
    UInt32 propertySize = sizeof (maxPacketSize);
    AudioFileGetProperty (_myinfo.mAudioFile, kAudioFilePropertyPacketSizeUpperBound, &propertySize, &maxPacketSize);
    
    DeriveBufferSize(_myinfo.mDataFormat, maxPacketSize, 0.5, &_myinfo.bufferByteSize, &_myinfo.mNumPacketsToRead);
    
    NSLog(@"Buffer Byte size: %d\n", _myinfo.bufferByteSize);
    NSLog(@"Number of Packets to read size: %d\n", _myinfo.mNumPacketsToRead);
    
    bool isFormatVBR = (_myinfo.mDataFormat.mBytesPerPacket == 0 || _myinfo.mDataFormat.mFramesPerPacket == 0);
    
    if (isFormatVBR) {
        _myinfo.mPacketDescs = (AudioStreamPacketDescription*) malloc (_myinfo.mNumPacketsToRead * sizeof (AudioStreamPacketDescription));
    } else {
        _myinfo.mPacketDescs = NULL;
    }
    
}

- (void)play
{
    if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        return [self performSelectorOnMainThread:@selector(play) withObject:nil waitUntilDone:YES];
    }
    
    NSLog(@"Allocating and starting music thread\n");
    self.musicThread = [[NSThread alloc] initWithTarget:self selector:@selector(startQueue) object:nil];
    [self.musicThread start];
}

/*
 // Leaving out MagicCookie for the moment
 UInt32 cookieSize = sizeof (UInt32);
 bool couldNotGetProperty = AudioFileGetPropertyInfo (_myinfo.mAudioFile, kAudioFilePropertyMagicCookieData, &cookieSize,NULL);
 
 
 if (!couldNotGetProperty && cookieSize) {
 char* magicCookie = (char *) malloc (cookieSize);
 
 AudioFileGetProperty (_myinfo.mAudioFile, kAudioFilePropertyMagicCookieData, &cookieSize, magicCookie);
 AudioQueueSetProperty (_myinfo.mQueue, kAudioQueueProperty_MagicCookie, magicCookie, cookieSize);
 
 free (magicCookie);
 }
 */

- (void)startQueue
{
    _myinfo.mIsRunning = true;
    error = AudioQueueNewOutput (&_myinfo.mDataFormat, AQTestBufferCallback, &_myinfo, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &_myinfo.mQueue);
    NSLog(@"Just called queue new output with error code: %d\n", error);
    
    for (int i = 0; i < kNumberBuffers; ++i) {
        error = AudioQueueAllocateBuffer (_myinfo.mQueue, _myinfo.bufferByteSize, &_myinfo.mBuffers[i]);
        NSLog(@"Just called queue allocate buffer with error code: %d\n", error);
        AQTestBufferCallback(&_myinfo, _myinfo.mQueue, _myinfo.mBuffers[i]);
    }
    
    Float32 gain = 1.0;
    // Optionally, allow user to override gain setting here
    AudioQueueSetParameter (_myinfo.mQueue, kAudioQueueParam_Volume, gain);
    
    _myinfo.mIsRunning = true;
    NSLog(@"Set is Running to: %d\n", _myinfo.mIsRunning);
    
    error = AudioQueueStart (_myinfo.mQueue, NULL);
    NSLog(@"Just called queue start with error code: %d\n", error);
    
    while (_myinfo.mIsRunning && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ;
    
}

- (void)stopQueue
{
    AudioQueueStop(_myinfo.mQueue, YES);
    _myinfo.mIsRunning = NO;
}

static char *FormatError(char *str, OSStatus error)
{
    // see if it appears to be a 4-char-code
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
    return str;
}

static void AQTestBufferCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inCompleteAQBuffer) {
    struct myAQStruct *myInfo = (struct myAQStruct *)inUserData;
    NSLog(@"Buffer callback with misRunning: %d\n", myInfo->mIsRunning);
    if (myInfo->mIsRunning == 0) return;
    NSLog(@"Filling Buffer\n");
    UInt32 numBytes;
    UInt32 nPackets = myInfo->mNumPacketsToRead;
    
    OSStatus i = AudioFileReadPackets (myInfo->mAudioFile, false, &numBytes, myInfo->mPacketDescs, myInfo->mCurrentPacket, &nPackets, inCompleteAQBuffer->mAudioData);
    char error[7];
    FormatError(error, i);
    NSLog(@"AudioFileReadPackets with error code: %s\n", error);
    
    if (nPackets > 0) {
        inCompleteAQBuffer->mAudioDataByteSize = numBytes;
        i = AudioQueueEnqueueBuffer (inAQ, inCompleteAQBuffer, (myInfo->mPacketDescs ? nPackets : 0), myInfo->mPacketDescs);
        NSLog(@"Just called enqueue buffer with error code: %d\n", i);
        myInfo->mCurrentPacket += nPackets;
    } else {
        i = AudioQueueStop (myInfo->mQueue, false);
        NSLog(@"Just called queue stop with error code: %d\n", i);
        myInfo->mIsRunning = false;
    }
}

void DeriveBufferSize (AudioStreamBasicDescription ASBDesc, UInt32 maxPacketSize, Float64 seconds, UInt32 *outBufferSize, UInt32 *outNumPacketsToRead) {
    static const int maxBufferSize = 0x50000;
    static const int minBufferSize = 0x4000;
    
    if (ASBDesc.mFramesPerPacket != 0) {
        Float64 numPacketsForTime = ASBDesc.mSampleRate / ASBDesc.mFramesPerPacket * seconds;
        *outBufferSize = numPacketsForTime * maxPacketSize;
    } else {
        *outBufferSize = maxBufferSize > maxPacketSize ? maxBufferSize : maxPacketSize;
    }
    
    if (*outBufferSize > maxBufferSize && *outBufferSize > maxPacketSize)
        *outBufferSize = maxBufferSize;
    else {
        if (*outBufferSize < minBufferSize)
            *outBufferSize = minBufferSize;
    }
    
    *outNumPacketsToRead = *outBufferSize / maxPacketSize;
}

@end
