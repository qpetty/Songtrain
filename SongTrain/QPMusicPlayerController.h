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
#import "ControlPanel.h"

@protocol QPMusicPlayerControllerDelegate <NSObject>

- (void)playListHasBeenUpdated;

@end

@interface QPMusicPlayerController : NSObject

@property (weak, nonatomic) id <QPMusicPlayerControllerDelegate> delegate;

@property (nonatomic, retain, readonly) Song *currentSong;
@property (atomic, assign, readonly) NSRange currentSongTime;
@property (atomic, assign, readonly) BOOL currentlyPlaying;

@property (nonatomic, retain) NSMutableArray *playlist;
@property (weak, nonatomic) ControlPanel *panel;

@property (nonatomic, readonly) AudioStreamBasicDescription *audioFormat;

+ (instancetype)musicPlayer;

- (void)addSongToPlaylist:(Song*)song;
- (void)addSongsToPlaylist:(NSMutableArray*)songs;
- (void)removeSongFromPlaylist:(NSUInteger)ndx;
- (void)switchSongFromIndex:(NSUInteger)ndx to:(NSUInteger)ndx2;

- (void)play;
- (void)skip;
@end
