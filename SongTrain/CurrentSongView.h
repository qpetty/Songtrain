//
//  CurrentSongView.h
//  SongTrain
//
//  Created by Quinton Petty on 1/21/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UsefulFunctions.h"

enum ButtonNames : NSInteger {
    InfoButton = 1,
    FavoriteButton = 2,
    MuteButton = 3
};

@protocol CurrentSongViewDelegate <NSObject>

- (void)buttonPressed:(UIButton*)sender;

@end

@interface CurrentSongView : UIImageView{
    MPMusicPlayerController *musicPlayer;
    MPMediaItem *currentSong;
    UILabel *songTitle;
    UILabel *songArtist;
    
    UIButton *infoButton;
    UIButton *favoriteButton;
    UIButton *muteButton;

    UIProgressView *songProgress;
    NSTimer *progressTimer;
}

@property (weak, nonatomic) id <CurrentSongViewDelegate> delegate;
@property (nonatomic, assign, setter = setIsShowArtwork:) BOOL showArtwork;
@property (nonatomic, assign, setter = setIsShowInfoButton:) BOOL showInfoButton;

- (id)initWithPlayer:(MPMusicPlayerController*)player andFrame:(CGRect)frame;
- (void)updateSongInfo:(MPMediaItem*)song;
- (void)setIsShowArtwork:(BOOL)show;
- (void)setIsShowInfoButton:(BOOL)show;

- (void)addPlayer:(MPMusicPlayerController*)player;
- (void)nowPlayingItemChanged:(id)sender;
- (void)playbackStateChanged:(id)sender;

@end
