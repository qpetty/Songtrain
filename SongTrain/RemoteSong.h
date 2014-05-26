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

@interface RemoteSong : Song <NSStreamDelegate>

@property (strong, nonatomic) MCPeerID *peer;
@property (strong, nonatomic, setter = setInStream:) NSInputStream *inStream;

@property (atomic, assign, readonly) AudioFileStreamID fileStream;

- (instancetype)initWithSong:(Song*)song fromPeer:(MCPeerID*)peer andOutputASBD:(AudioStreamBasicDescription)audioStreamBD;

- (void)setInStream:(NSInputStream *)inStream;

@end
