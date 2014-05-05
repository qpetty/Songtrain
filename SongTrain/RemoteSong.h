//
//  RemoteSong.h
//  SongTrain
//
//  Created by Quinton Petty on 5/2/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "Song.h"
#import "QPSessionManager.h"

@interface RemoteSong : Song

@property (strong, nonatomic) MCPeerID *peer;

- (instancetype)initWithSong:(Song*)song fromPeer:(MCPeerID*)peer;

@end
