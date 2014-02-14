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

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *artistName;
@property (strong, nonatomic) UIImage *albumImage;
@property (strong, nonatomic) MCPeerID *host;
//Maybe needed not sure yet
@property (strong, nonatomic) MPMediaItem *media;
@property (strong, nonatomic) NSURL *url;

@property (nonatomic) int songPosition;
@property (nonatomic) int totalSongs;
@end
