//
//  ServerPlaylistViewController.h
//  SongTrain
//
//  Created by Quinton Petty on 2/2/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlaylistViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
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
    int  number;
};

@interface ServerPlaylistViewController : PlaylistViewController <MCNearbyServiceAdvertiserDelegate>{
    MCNearbyServiceAdvertiser *advert;
    struct myAQStruct myinfo;
}

@end
