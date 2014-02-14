//
//  ViewController.h
//  SongTrain
//
//  Created by Quinton Petty on 1/21/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <CoreImage/CoreImage.h>

#import "QPMusicPlayerController.h"

#import "CurrentSongView.h"
#import "SingleCellButton.h"
#import "GrayTableView.h"
#import "InfoViewController.h"
#import "Animator.h"
#import "ServerPlaylistViewController.h"
#import "ClientPlaylistViewController.h"
#import "InfoViewController.h"

#define HEIGHT_BEFORE_TABLEVIEW 60

@interface MainViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MCNearbyServiceBrowserDelegate, MCSessionDelegate, CurrentSongViewDelegate, ControlPanelDelegate,
    UINavigationControllerDelegate>{
    
    UILabel *label;
    InfoViewController *infoView;
    GrayTableView *mainTableView;
    ControlPanel *panel;
    
    QPMusicPlayerController *musicPlayer;
    
    MCSession *mainSession;
    MCNearbyServiceBrowser *browse;
    MCPeerID *pid;
    NSString *service;
    
    NSMutableArray *peerArray;
    UIImage *songNotPlayingHeader;

    UIImageView *newView;
    id<UIViewControllerAnimatedTransitioning> animator;
}
@property (strong, nonatomic) CurrentSongView *albumArtwork;
@property (strong, nonatomic) SingleCellButton *createTrainButton;
@property (strong, nonatomic) UIImageView *navBarHairlineImageView;

@end
