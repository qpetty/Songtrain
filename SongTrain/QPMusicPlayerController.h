//
//  QPMusicPlayerController.h
//  SongTrain
//
//  Created by Quinton Petty on 2/10/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "LocalSong.h"
#import "RemoteSong.h"

@interface QPMusicPlayerController : NSObject

@property (nonatomic, retain, readonly) Song *currentSong;
@property (atomic, assign, readonly) NSRange currentSongTime;
@property (atomic, assign, readonly) BOOL currentlyPlaying;

@property (nonatomic, retain) NSMutableArray *playlist;

@property (nonatomic, readonly) AudioStreamBasicDescription *audioFormat;

+ (instancetype)sharedMusicPlayer;

- (void)reset;
- (void)resetToServer;
- (void)resetToClient;

- (void)currentTime:(NSUInteger)time;

- (void)addSongToPlaylist:(Song*)song;
- (void)addSongsToPlaylist:(NSMutableArray*)songs;
- (void)removeSongFromPlaylist:(NSUInteger)ndx;
- (void)switchSongFromIndex:(NSUInteger)ndx to:(NSUInteger)ndx2;

- (void)play;
- (void)skip;
- (void)nextSong;

- (void)updateNowPlaying;
- (BOOL)isRunning;
@end
