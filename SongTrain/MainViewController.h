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
#import "CurrentSongView.h"
#import "SingleCellButton.h"
#import "GrayTableView.h"
#import "InfoViewController.h"
#import "ServerPlaylistViewController.h"
#import "ClientPlaylistViewController.h"
#import "NSMutableArray+Playlist.h"

#import "ControlPanel.h"

#define HEIGHT_BEFORE_TABLEVIEW 60

@interface MainViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MCNearbyServiceBrowserDelegate, MCSessionDelegate, CurrentSongViewDelegate, ControlPanelDelegate>{
    
    UILabel *label;
    InfoViewController *infoView;
    GrayTableView *mainTableView;
    ControlPanel *panel;
    
    NSMutableArray *playlist;
    
    MCSession *mainSession;
    MCNearbyServiceBrowser *browse;
    MCPeerID *pid;
    NSString *service;
    
    NSMutableArray *peerArray;
    UIImage *songNotPlayingHeader;
}
@property (strong, nonatomic) CurrentSongView *albumArtwork;
@property (strong, nonatomic) SingleCellButton *createTrainButton;
@property (strong, nonatomic) UIImageView *navBarHairlineImageView;

@end
