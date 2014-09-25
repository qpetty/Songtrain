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

@class RemoteSong;

@protocol RemoteSongProtocol <NSObject>

- (void)needMoreData:(RemoteSong*)song;

@end

@interface RemoteSong : Song <NSStreamDelegate>

@property (strong, nonatomic) MCPeerID *peer;

- (instancetype)initWithSong:(Song*)song fromPeer:(MCPeerID*)peer andOutputASBD:(AudioStreamBasicDescription)audioStreamBD;
- (void)submitBytes:(NSData*)bytes;

@end
