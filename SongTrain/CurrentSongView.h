//
//  CurrentSongView.h
//  SongTrain
//
//  Created by Quinton Petty on 1/21/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

#ifndef HEX_COLOR
#define HEX_COLOR
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#endif

enum ButtonNames : NSInteger {
    InfoButton = 1,
    FavoriteButton = 2,
    MuteButton = 3
};

@protocol CurrentSongViewDelegate <NSObject>

- (void)buttonPressed:(UIButton*)sender;

@end

@interface CurrentSongView : UIImageView{
    MPMediaItem *currentSong;
    UILabel *songTitle;
    UILabel *songArtist;
    
    UIButton *infoButton;
    UIButton *favoriteButton;
    UIButton *muteButton;

    UIProgressView *songProgress;
}

@property (weak, nonatomic) id <CurrentSongViewDelegate> delegate;

- (id)initWithSong:(MPMediaItem*)song andFrame:(CGRect)frame;
- (void)updateSongInfo:(MPMediaItem*)song;
- (void)updateProgressBar:(NSTimeInterval)time;

@end
