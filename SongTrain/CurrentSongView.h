//
//  CurrentSongView.h
//  SongTrain
//
//  Created by Quinton Petty on 1/21/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QPMusicPlayerController.h"
#import "UsefulFunctions.h"
#import "MarqueeLabel.h"

@interface CurrentSongView : UIImageView{
    Song *currentSong;
    UILabel *songTitle;
    UILabel *songArtist;
    UIView *blurFilter;
}

@property (nonatomic, assign, setter = setIsShowArtwork:) BOOL showArtwork;
@property (nonatomic, assign, setter = setIsShowInfoButton:) BOOL showInfoButton;
@property (strong) UIImageView *tinyAlbumView;

- (id)initWithSong:(Song*)song andFrame:(CGRect)frame;
- (void)updateSongInfo:(Song*)song;
- (void)setIsShowArtwork:(BOOL)show;

@end
