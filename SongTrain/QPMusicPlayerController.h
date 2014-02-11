//
//  QPMusicPlayerController.h
//  SongTrain
//
//  Created by Quinton Petty on 2/10/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "NSMutableArray+Playlist.h"

@interface QPMusicPlayerController : NSObject{
    NSMutableArray *playlist;
    MCPeerID *pid;
}

@property (nonatomic, retain) Song *currentSong;

+ (id)musicPlayer;

@end
