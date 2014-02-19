//
//  ViewController.h
//  SongTrain
//
//  Created by Quinton Petty on 1/21/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CoreImage/CoreImage.h>

#import "QPMusicPlayerController.h"
#import "QPSessionManager.h"

#import "CurrentSongView.h"
#import "SingleCellButton.h"
#import "GrayTableView.h"
#import "InfoViewController.h"
#import "Animator.h"
#import "ServerPlaylistViewController.h"
#import "ClientPlaylistViewController.h"
#import "InfoViewController.h"

#import "ControlPanel.h"

#define HEIGHT_BEFORE_TABLEVIEW 60

@interface MainViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, QPSessionManagerDelegate, CurrentSongViewDelegate, ControlPanelDelegate, UINavigationControllerDelegate>{
    
    UILabel *label;
    InfoViewController *infoView;
    GrayTableView *mainTableView;
    ControlPanel *panel;
    
    QPMusicPlayerController *musicPlayer;
    QPSessionManager *sessionManager;
    
    UIImage *songNotPlayingHeader;

    UIImageView *newView;
    Animator *animator;
}
@property (strong, nonatomic) CurrentSongView *albumArtwork;
@property (strong, nonatomic) SingleCellButton *createTrainButton;
@property (strong, nonatomic) UIImageView *navBarHairlineImageView;

@end
