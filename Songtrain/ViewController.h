//
//  ViewController.h
//  Songtrain
//
//  Created by Quinton Petty on 9/18/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "MusicPickerViewController.h"
#import "MarqueeLabel.h"
#import "ControlPanelView.h"
#import "QPMusicPlayerController.h"
#import "AnimatedCollectionViewCell.h"
#import "QPSessionManager.h"

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, MusicPickerViewControllerDelegate, QPBrowsingManagerDelegate, QPSessionDelegate, ControlPanelDelegate, UICollectionViewDataSource, UICollectionViewDelegate, QPMusicPlayerPlaylistDelegate, SKStoreProductViewControllerDelegate>

@property (weak) IBOutlet UITableView *songTableView;
@property (weak) IBOutlet UITableView *peerTableView;

@property (weak) IBOutlet UILabel *mainTitle;

@property (weak) IBOutlet MarqueeLabel *currentSongTitle;
@property (weak) IBOutlet MarqueeLabel *currentSongArtist;
@property (weak) IBOutlet UIImageView *currentAlbumArtwork;
@property (weak) IBOutlet UIImageView *streamingServiceIcon;

@property (weak) IBOutlet UIButton *browseForOtherTrains;
@property (weak) IBOutlet UIButton *editTableViews;

@property (weak) IBOutlet UISegmentedControl *tracksAndPassengers;

@property (weak) IBOutlet UIProgressView *progressBar;
@property (weak) IBOutlet ControlPanelView *controlBar;

@property (weak) IBOutlet UIImageView *addHelper;

@property BOOL onScreen;

-(void)updatePlayOrPauseImage;
-(void)showPurchaseButton;
@end

