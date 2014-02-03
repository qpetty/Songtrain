//
//  PlaylistViewController.h
//  SongTrain
//
//  Created by Quinton Petty on 1/26/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "UsefulFunctions.h"
#import "CurrentSongView.h"
#import "InfoViewController.h"
#import "GrayTableView.h"
#import "Song.h"

@interface PlaylistViewController : UIViewController <CurrentSongViewDelegate, MPMediaPickerControllerDelegate, UITableViewDelegate, UITableViewDataSource, MCSessionDelegate>{
    BOOL isHost;
    
    MPMusicPlayerController *musicPlayer;
    MPMediaItemCollection *currentPlaylist;
    MPMediaPickerController *picker;
    
    NSMutableArray *playlist;
    
    CurrentSongView *albumArtwork;
    InfoViewController *infoView;
    GrayTableView *mainTableView;
    
    UIButton *addToList;
    
    MCSession *mainSession;
    MCPeerID *pid;
    NSString *service;
}

- (instancetype)initWithSession:(MCSession*)session;

@end
