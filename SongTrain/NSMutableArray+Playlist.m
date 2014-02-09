//
//  NSMutableArray+Playlist.m
//  SongTrain
//
//  Created by Quinton Petty on 2/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "NSMutableArray+Playlist.h"

@implementation NSMutableArray (Playlist)

- (void)addSongFromMediaItemToList:(MPMediaItem*)item withPeerID:(MCPeerID*)pid
{
    Song *nowPlayingSong = [[Song alloc] init];
    nowPlayingSong.title = [item valueForProperty:MPMediaItemPropertyTitle];
    nowPlayingSong.artistName = [item valueForProperty:MPMediaItemPropertyArtist];
    nowPlayingSong.host = pid;
    nowPlayingSong.media = item;
    nowPlayingSong.url = [item valueForProperty:MPMediaItemPropertyAssetURL];
    
    [self addObject:nowPlayingSong];
}

- (void)addSongToList:(Song*)item
{
    [self addObject:item];
}

@end
