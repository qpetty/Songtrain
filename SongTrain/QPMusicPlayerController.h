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

@interface QPMusicPlayerController : NSObject{
    NSTimer *timer;
    BOOL currentlyPlaying;
}

@property (weak, nonatomic) id <QPMusicPlayerControllerDelegate> delegate;
@property (nonatomic, retain, readonly) Song *currentSong;
@property (nonatomic, retain) NSMutableArray *playlist;
@property (weak, nonatomic) ControlPanel *panel;

@property (nonatomic, readonly) AudioStreamBasicDescription *audioFormat;

+ (id)musicPlayer;
- (void)addSongsToPlaylist:(NSMutableArray*)songs;

- (void)play;
//- (void)skip;
@end
