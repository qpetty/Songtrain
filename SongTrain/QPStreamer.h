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
    UInt32                          nextBufferToBeFilled;
    UInt32                          bytesThatNeedToBeFilled;
    UInt32                          mNumPacketsToRead;
    
    UInt32                          bufferByteSize;
    AudioStreamPacketDescription    *mPacketDescs;
    bool                            mIsRunning;
    bool                            readyToPlay;
    CFReadStreamRef                 inputStream;
};

@interface QPStreamer : NSObject

- (void)setInputStream:(NSInputStream*)inputStream;

@end
