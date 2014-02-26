//
//  QPInputStreamer.h
//  SongTrain
//
//  Created by Quinton Petty on 2/25/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

static const int kNumberBuffers = 3;
static const int kBufferSize = 0x4000;

struct AudioPacket{
    UInt32  packetSize;
    UInt32  numFrames;
    void    *data;
    struct AudioPacket *next;
};

struct AudioStreamInfo{
    AudioFileStreamID               streamID;
    AudioQueueRef                   audioQueue;
    AudioStreamBasicDescription     basicDescription;
    
    UInt32                          packetsInList;
    struct AudioPacket              *packetListHead;
    struct AudioPacket              *packetListTail;
    
    AudioStreamPacketDescription    packetDescription[512];
    UInt32                          packetsFilled;
};

@interface QPInputStreamer : NSObject <NSStreamDelegate>

- (void)setInputStream:(NSInputStream*)inputStream;

@end
