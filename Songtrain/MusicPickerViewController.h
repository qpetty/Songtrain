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

#import "CocoaSoundCloudUI/Sources/SoundCloudUI/SCUI.h"
#import "SoundCloudTabViewController.h"

@class MusicPickerViewController;

@protocol MusicPickerViewControllerDelegate <UITabBarControllerDelegate, MPMediaPickerControllerDelegate>

-(void)musicPicker:(MusicPickerViewController*)picker didPickItems:(NSArray*)items andMediaItems:(MPMediaItemCollection*)mediaItemCollection;

@end

@interface MusicPickerViewController : UITabBarController <TabViewControllerDelegate, SCLoginViewControllerDelegate>

@property (weak, nonatomic) id <MusicPickerViewControllerDelegate> delegate;
@property (readonly) NSArray *selectedMediaItems;

- (void)addItem:(MPMediaItem*)item;
- (void)removeItem:(MPMediaItem*)item;
- (BOOL)isItemSelected:(MPMediaItem*)item;
- (void)addButton:(UIBarButtonItem*)button;
- (void)removeButton:(UIBarButtonItem*)button;
- (void)done;

@end
