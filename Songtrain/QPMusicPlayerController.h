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
#import "SoundCloudSong.h"

@protocol QPMusicPlayerPlaylistDelegate <NSObject>

-(void)songAdded:(Song*)song atIndex:(NSUInteger)ndx;
-(void)songRemoved:(Song*)song atIndex:(NSInteger)ndx;
-(void)songsRemovedAtIndexSet:(NSIndexSet*)ndxSet;

-(void)songMoved:(Song*)song fromIndex:(NSUInteger)ndx1 toIndex:(NSUInteger)ndx2;

@end

@interface QPMusicPlayerController : NSObject

@property (weak) id <QPMusicPlayerPlaylistDelegate> delegate;

@property (readonly) Song *currentSong;
@property (atomic, assign, readonly) NSRange currentSongTime;
@property (atomic, assign, readonly) BOOL currentlyPlaying;

@property NSMutableArray *playlist;

@property (nonatomic, readonly) AudioStreamBasicDescription *audioFormat;

+ (instancetype)sharedMusicPlayer;

- (void)reset;
- (void)resetToServer;
- (void)resetToClient;

- (void)updateCurrentSong:(Song*)song;
- (void)currentTime:(NSUInteger)time;

- (void)addSongToPlaylist:(Song*)song;
- (void)addSongsToPlaylist:(NSMutableArray*)songs;
- (void)removeSongFromPlaylist:(NSUInteger)ndx;
- (void)removeSongIndexesFromPlaylist:(NSIndexSet*)set;
- (void)switchSongFromIndex:(NSUInteger)ndx to:(NSUInteger)ndx2;

- (void)play;
- (void)skip;
- (void)nextSong;

- (void)updateNowPlaying;
- (BOOL)isRunning;
@end
