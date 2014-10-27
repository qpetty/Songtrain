//
//  RemoteSong.h
//  SongTrain
//
//  Created by Quinton Petty on 5/2/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "Song.h"
#import "QPSessionManager.h"
#import "TPCircularBuffer.h"

static const int kBufferLength = 32768 * 32;

typedef enum RemoteSongType : NSInteger {
    MusicPlayerSong,
    SoundCloud
} RemoteSongType;

@class RemoteSong;

@protocol RemoteSongProtocol <NSObject>

- (void)needMoreData:(RemoteSong*)song;

@end

@interface RemoteSong : Song <NSStreamDelegate>

@property RemoteSongType type;
@property (strong, nonatomic) MCPeerID *peer;

- (instancetype)initWithSong:(Song*)song ofType:(RemoteSongType)type fromPeer:(MCPeerID*)peer andOutputASBD:(AudioStreamBasicDescription)audioStreamBD;
- (void)submitBytes:(NSData*)bytes;

@end
