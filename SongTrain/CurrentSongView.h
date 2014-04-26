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

@interface CurrentSongView : UIImageView{
    Song *currentSong;
    UILabel *songTitle;
    UILabel *songArtist;
}

@property (nonatomic, assign, setter = setIsShowArtwork:) BOOL showArtwork;

- (id)initWithSong:(Song*)song andFrame:(CGRect)frame;
- (void)updateSongInfo:(Song*)song;
- (void)setIsShowArtwork:(BOOL)show;

@end
