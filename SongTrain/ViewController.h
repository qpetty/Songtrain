//
//  ViewController.h
//  Songtrain
//
//  Created by Quinton Petty on 9/18/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MusicPickerViewController.h"
#import "MarqueeLabel.h"
@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, MusicPickerViewControllerDelegate>

@property IBOutlet UITableView *mainTableView;

@property IBOutlet MarqueeLabel *currentSongTitle;
@property IBOutlet UILabel *currentSongArtist;
@property IBOutlet UIImageView *currentAlbumArtwork;
@property IBOutlet UILabel *currentTime;
@property IBOutlet UILabel *totalTime;

@property IBOutlet UIButton *browseForOtherTrains;
@property IBOutlet UIButton *playOrPauseButton;

-(void)updatePlayOrPauseImage;

@end

