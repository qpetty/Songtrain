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
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive:YES error:nil];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        
        sessionManager = [QPSessionManager sessionManager];
        _playlist = [[NSMutableArray alloc] init];
        pid = [sessionManager pid];
        
        MPMediaItem *currentItem = [[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem];
        if (currentItem){
            [_playlist addSongFromMediaItemToList:currentItem withPeerID:pid];
            self.currentSong = [_playlist objectAtIndex:0];
        }
    }
    return self;
}

- (void)addSongsToPlaylist:(MPMediaItemCollection*)songs
{
    if (sessionManager.currentRole == ClientConnection) {
        NSMutableArray *proposedSongs = [[NSMutableArray alloc] init];
        for (MPMediaItem *item in songs){
            [proposedSongs addSongFromMediaItemToList:item withPeerID:pid];
        }
        [sessionManager sendData:[SongtrainProtocol dataFromSongArray:proposedSongs] ToPeer:sessionManager.server];
    }
    else if (sessionManager.currentRole == ServerConnection) {
        for (MPMediaItem *item in songs){
            [_playlist addSongFromMediaItemToList:item withPeerID:pid];
        }
        [sessionManager sendDataToAllPeers:[SongtrainProtocol dataFromSongArray:_playlist]];
    }
}

- (void)addArrayOfSongsToPlaylist:(NSMutableArray *)songs
{
    for (Song *item in songs){
        [_playlist addSongToList:item];
    }
}

- (void)removeSongsWithPeerID:(MCPeerID*)peerID
{
    int i = 0;
    while (i < _playlist.count) {
        //NSLog(@"Looking at song: %@", [playlist objectAtIndex:i]);
        //NSLog(@"Host is: %@", [[playlist objectAtIndex:i] host]);
        if ([peerID.displayName isEqualToString:[ (MCPeerID*)[[_playlist objectAtIndex:i] host] displayName]]) {
            [_playlist removeObjectAtIndex:i];
        }
        else{
            i++;
        }
    }
}

- (void)fillOutStream:(NSOutputStream*)outStream FromSong:(Song*)singleSong
{
    if (audioOutStream) {
        [audioOutStream stop];
    }
    audioOutStream = [[TDAudioOutputStreamer alloc] initWithOutputStream:outStream];
    NSLog(@"Trying to play media item: %@\n", singleSong.media);
    NSLog(@"URL of item: %@\n", [singleSong.media valueForProperty:MPMediaItemPropertyAssetURL]);
    NSLog(@"URL from song: %@\n", singleSong.url);
    [audioOutStream streamAudioFromURL:singleSong.url];
    [audioOutStream start];
}

- (void)stopOutStream
{
    if (audioOutStream) {
        [audioOutStream stop];
    }
}

- (void)recievedStream:(NSInputStream*)inputStream
{
    if (audioInStream) {
        [audioInStream stop];
    }
    audioInStream = [[TDAudioInputStreamer alloc] initWithInputStream:inputStream];
    [audioInStream start];
    //NSLog(@"Received Stream: %@\n", streamName);
}

- (void)playNextSong
{
    if (!_playlist.count) {
        //No songs in list
        return;
    }
    
    NSLog(@"Trying to play the next song\n");
    
    Song *nextSong = [_playlist firstObject];
    
    if (audioPlayer){
        [audioPlayer stop];
        audioPlayer = nil;
    }
    
    if (audioInStream){
        [audioInStream pause];
        [audioInStream stop];
        audioInStream = nil;
    }
    
    if ([nextSong.host.displayName isEqualToString:[pid displayName]]) {
        
        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[nextSong media] valueForProperty:MPMediaItemPropertyAssetURL] error:nil];
        audioPlayer.delegate = self;
        [audioPlayer play];
        
        NSLog(@"Sending meida item: %@\n", nextSong.media);
        NSLog(@"URL of item: %@\n", [nextSong.media valueForProperty:MPMediaItemPropertyAssetURL]);
        
        NSLog(@"Beginning Local Song\n");
    }
    else{
        [sessionManager sendData:[SongtrainProtocol dataFromMedia:nextSong] ToPeer:nextSong.host];
        NSLog(@"Playing Song from %@\n", nextSong.host.displayName);
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self finishedPlayingSong];
}

- (void)pause
{
    if (audioPlayer)
        [audioPlayer pause];
    else if (audioInStream)
        [audioInStream pause];
}

- (void)resume
{
    if (audioPlayer)
        [audioPlayer play];
    else if (audioInStream)
        [audioInStream resume];
}

- (void)finishedPlayingSong
{
    [_playlist removeObjectAtIndex:0];
    [self playNextSong];
}

@end
