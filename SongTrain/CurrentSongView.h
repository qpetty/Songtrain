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
    InfoButton = 1
};

@protocol CurrentSongViewDelegate <NSObject>

- (void)buttonPressed:(UIButton*)sender withSong:(Song*)song;

@end

@interface CurrentSongView : UIImageView{
    Song *currentSong;
    UILabel *songTitle;
    UILabel *songArtist;
    
    UIButton *infoButton;
}

@property (weak, nonatomic) id <CurrentSongViewDelegate> delegate;
@property (nonatomic, assign, setter = setIsShowArtwork:) BOOL showArtwork;
@property (nonatomic, assign, setter = setIsShowInfoButton:) BOOL showInfoButton;

- (id)initWithSong:(Song*)song andFrame:(CGRect)frame;
- (void)updateSongInfo:(Song*)song;
- (void)setIsShowArtwork:(BOOL)show;
- (void)setIsShowInfoButton:(BOOL)show;

@end
