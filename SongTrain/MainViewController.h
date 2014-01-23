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

#ifndef HEX_COLOR
#define HEX_COLOR
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#endif

#define ARTWORK_HEIGHT 138.0

@interface MainViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MCNearbyServiceBrowserDelegate, MCSessionDelegate, CurrentSongViewDelegate>{
    MPMusicPlayerController *musicPlayer;
    MPMediaItem *currentSong;
    NSTimer *progressTimer;
    UILabel *label;
    GrayTableView *mainTableView;
    
    MCSession *session;
    MCNearbyServiceBrowser *browse;
    MCPeerID *pid;
    NSString *service;
    
    NSMutableArray *peerArray;
}
@property (strong, nonatomic) CurrentSongView *albumArtwork;
@property (strong, nonatomic) SingleCellButton *createTrainButton;

@end
