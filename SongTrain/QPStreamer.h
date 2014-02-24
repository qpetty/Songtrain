//
//  QPStreamer.h
//  SongTrain
//
//  Created by Quinton Petty on 2/23/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

static const int kNumberBuffers = 3;

struct myAQStruct {
    AudioFileID                     mAudioFile;
    AudioFileStreamID               streamID;
    //CAStreamBasicDescription        mDataFormat;
    AudioStreamBasicDescription     mDataFormat;
    AudioQueueRef                   mQueue;
    AudioQueueBufferRef             mBuffers[kNumberBuffers];
    UInt32                          bufferByteSize;
    SInt64                          mCurrentPacket;
    UInt32                          mNumPacketsToRead;
    AudioStreamPacketDescription    *mPacketDescs;
    bool                            mIsRunning;
    bool                            readyToPlay;
    UInt32                          nextBufferToBeFilled;
    CFReadStreamRef                 inputStream;
};

@interface QPStreamer : NSObject

- (void)setInputStream:(NSInputStream*)inputStream;

@end
