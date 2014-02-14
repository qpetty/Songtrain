//
//  QPMusicPlayerController.m
//  SongTrain
//
//  Created by Quinton Petty on 2/10/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "QPMusicPlayerController.h"

@implementation QPMusicPlayerController

+ (id)musicPlayer {
    static QPMusicPlayerController *sharedMusicPlayer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMusicPlayer = [[self alloc] init];
    });
    return sharedMusicPlayer;
}

- (id)init {
    if (self = [super init]) {
        playlist = [[NSMutableArray alloc] init];
        
        //Fix later: need to create a connection singleton object
        pid = nil;
        
        MPMediaItem *currentItem = [[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem];
        if (currentItem){
            [playlist addSongFromMediaItemToList:currentItem withPeerID:pid];
            self.currentSong = [playlist objectAtIndex:0];
        }
    }
    return self;
}

@end
