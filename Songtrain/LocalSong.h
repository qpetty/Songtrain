//
//  LocalSong.h
//  SongTrain
//
//  Created by Quinton Petty on 4/12/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "Song.h"
#import <AudioToolbox/AudioToolbox.h>

#define PICTURE_HEIGHT_AND_WIDTH 320.0

@interface LocalSong : Song <NSStreamDelegate>

@property (strong, nonatomic) AVURLAsset *assetURL;
@property (strong, nonatomic) NSNumber *persistantID;

- (instancetype)initWithItem:(MPMediaItem*)item andOutputASBD:(AudioStreamBasicDescription)audioStreanBasicDescription andPeer:(MCPeerID*)peer;

@end
