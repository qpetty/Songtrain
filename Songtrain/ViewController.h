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
#import "ControlPanelView.h"
#import "QPMusicPlayerController.h"
#import "AnimatedCollectionViewCell.h"
#import "QPSessionManager.h"

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, MusicPickerViewControllerDelegate, QPBrowsingManagerDelegate, QPSessionDelegate, ControlPanelDelegate, UICollectionViewDataSource, UICollectionViewDelegate, QPMusicPlayerPlaylistDelegate>

@property (weak) IBOutlet UITableView *songTableView;
@property (weak) IBOutlet UITableView *peerTableView;

@property (weak) IBOutlet UILabel *mainTitle;

@property (weak) IBOutlet MarqueeLabel *currentSongTitle;
@property (weak) IBOutlet MarqueeLabel *currentSongArtist;
@property (weak) IBOutlet UIImageView *currentAlbumArtwork;

@property (weak) IBOutlet UIButton *browseForOtherTrains;
@property (weak) IBOutlet UIButton *editTableViews;

@property (weak) IBOutlet UISegmentedControl *tracksAndPassengers;

@property (weak) IBOutlet UIProgressView *progressBar;
@property (weak) IBOutlet ControlPanelView *controlBar;

@property UIImageView *backgroundImage;
@property UIImageView *backgroundOverlay;

@property UICollectionView *nearbyTrainsModal;
@property UIView *nearbyTrainBackground;

@property NSInteger lastIndex;

-(void)updatePlayOrPauseImage;

@end

