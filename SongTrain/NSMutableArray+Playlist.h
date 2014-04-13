//
//  NSMutableArray+Playlist.h
//  SongTrain
//
//  Created by Quinton Petty on 2/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <AVFoundation/AVFoundation.h>

@interface NSMutableArray (Playlist)

- (void)addSongFromMediaItemToList:(MPMediaItem*)item withPeerID:(MCPeerID*)pid;
- (void)addSongToList:(Song*)item;

@end
