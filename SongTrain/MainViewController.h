//
//  ViewController.h
//  SongTrain
//
//  Created by Quinton Petty on 1/21/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "CurrentSongView.h"

#ifndef HEX_COLOR
#define HEX_COLOR
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#endif

#define ARTWORK_HEIGHT 138.0

@interface MainViewController : UIViewController <CurrentSongViewDelegate>{
    MPMusicPlayerController *musicPlayer;
    MPMediaItem *currentSong;
    NSTimer *progressTimer;
}
@property (strong, nonatomic) CurrentSongView *albumArtwork;
@property (strong, nonatomic) UILabel *songTitle;
@property (strong, nonatomic) UILabel *songArtist;


@end
