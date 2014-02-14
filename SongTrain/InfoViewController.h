//
//  InfoViewController.h
//  SongTrain
//
//  Created by Quinton Petty on 1/24/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UsefulFunctions.h"
#import "CurrentSongView.h"

#define ALBUM_SIZE 300
#define SONG_INFO_HEIGHT 130

@interface InfoViewController : UIViewController{
    Song *currentSong;
    UIImageView *albumArtwork;
    CurrentSongView *songView;
}

- (id)initWithSong:(Song*)song;
- (void)updateSong:(Song*)song;

@end
