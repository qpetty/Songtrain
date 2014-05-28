//
//  MusicPickerViewController.h
//  SongTrain
//
//  Created by Quinton Petty on 4/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "SongTabViewController.h"
#import "PlaylistTabViewController.h"
#import "ArtistTabViewController.h"
#import "MusicNavigationViewController.h"

@class MusicPickerViewController;

@protocol MusicPickerViewController <UITabBarControllerDelegate, MPMediaPickerControllerDelegate>

@end

@interface MusicPickerViewController : UITabBarController

@property (weak, nonatomic) id <MusicPickerViewController> delegate;

- (void)addItem:(MPMediaItem*)item;
- (void)removeItem:(MPMediaItem*)item;
- (BOOL)isItemSelected:(MPMediaItem*)item;

@end
