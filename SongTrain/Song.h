//
//  Song.h
//  SongTrain
//
//  Created by Quinton Petty on 1/28/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <MediaPlayer/MediaPlayer.h>

@interface Song : NSObject <NSCoding>

@property (weak, nonatomic) NSString *title;
@property (weak, nonatomic) NSString *name;
@property (weak, nonatomic) MCPeerID *host;
//Maybe needed not sure yet
@property (weak, nonatomic) MPMediaItem *media;

@property (nonatomic) int songPosition;
@property (nonatomic) int totalSongs;
@end
