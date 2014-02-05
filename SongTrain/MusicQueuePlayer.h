//
//  MusicQueuePlayer.h
//  SongTrain
//
//  Created by Quinton Petty on 2/4/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>

//#import "CAStreamBasicDescription.h"

static const int kNumberBuffers = 3;
// Create a data structure to manage information needed by the audio queue
struct myAQStruct {
    AudioFileID                     mAudioFile;
    //CAStreamBasicDescription        mDataFormat;
    AudioStreamBasicDescription     mDataFormat;
    AudioQueueRef                   mQueue;
    AudioQueueBufferRef             mBuffers[kNumberBuffers];
    UInt32                          bufferByteSize;
    SInt64                          mCurrentPacket;
    UInt32                          mNumPacketsToRead;
    AudioStreamPacketDescription    *mPacketDescs;
    bool                            mIsRunning;
};

@interface MusicQueuePlayer : NSObject{
    //struct myAQStruct myinfo;
    
    NSURL *currentURL;
    
    OSStatus error;
    char errorString[7];
}

@property (strong, nonatomic) NSThread *musicThread;

@property (assign, atomic) struct myAQStruct myinfo;

- (instancetype)initWithUrl:(NSURL *)url;

- (void)setURL:(NSURL *)url;
- (void)play;
- (void)stopQueue;
@end
