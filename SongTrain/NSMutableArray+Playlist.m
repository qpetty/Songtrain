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
    
    MPMediaItemArtwork *albumItem = [item valueForProperty:MPMediaItemPropertyArtwork];
    if (albumItem){
        NSLog(@"Adding Image to Song\n");
        nowPlayingSong.albumImage = [albumItem imageWithSize:CGSizeMake(albumItem.bounds.size.width, albumItem.bounds.size.height)];
    }
    else
        NSLog(@"No Current Image\n");
    
    [self addObject:nowPlayingSong];
}

- (void)addSongToList:(Song*)item
{
    [self addObject:item];
}

@end
