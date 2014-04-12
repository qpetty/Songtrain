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
    nowPlayingSong.url = [item valueForProperty:MPMediaItemPropertyAssetURL];
    /*
    MPMediaItemArtwork *albumItem = [item valueForProperty:MPMediaItemPropertyArtwork];
    if (albumItem)
        nowPlayingSong.albumImage = [albumItem imageWithSize:CGSizeMake(albumItem.bounds.size.width, albumItem.bounds.size.height)];
    */
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:nowPlayingSong.url options:nil];
    AVAssetTrack* songTrack = [asset.tracks objectAtIndex:0];
    NSArray* formatDesc = songTrack.formatDescriptions;
    CMAudioFormatDescriptionRef description = (__bridge CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:0];
    const AudioStreamBasicDescription* bobTheDesc = CMAudioFormatDescriptionGetStreamBasicDescription (description);
    
    /*
    NSLog(@"Song Title: %@\n", nowPlayingSong.title);
    NSLog(@"Looking at URL: %@\n", nowPlayingSong.url);
    NSLog(@"Tracks Found: %d\n",asset.tracks.count);
    NSLog(@"Format Descriptions Found: %d\n",formatDesc.count);
    */
    
    if (bobTheDesc) {
        NSLog(@"ASBD Sample Rate: %lf\n",bobTheDesc->mSampleRate);
        NSLog(@"     Format ID: %8x\n",(unsigned int)bobTheDesc->mFormatID);
        NSLog(@"     Format Flags: %u\n",(unsigned int)bobTheDesc->mFormatFlags);
        NSLog(@"     Bytes per Packet: %u\n",(unsigned int)bobTheDesc->mBytesPerPacket);
        NSLog(@"     Frames per Packet: %u\n",(unsigned int)bobTheDesc->mFramesPerPacket);
        NSLog(@"     Bytes per Frame: %u\n",(unsigned int)bobTheDesc->mBytesPerFrame);
        NSLog(@"     Channels per Frame: %u\n",(unsigned int)bobTheDesc->mChannelsPerFrame);
        NSLog(@"     Bits per Channel: %u\n",(unsigned int)bobTheDesc->mBitsPerChannel);
        
        //memcpy(nowPlayingSong.asbd, bobTheDesc, sizeof(AudioStreamBasicDescription));
    }
    
    [self addObject:nowPlayingSong];
}

- (void)addSongToList:(Song*)item
{
    [self addObject:item];
}

@end
