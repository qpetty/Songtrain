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
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "UsefulFunctions.h"
#import "CurrentSongView.h"
#import "InfoViewController.h"
#import "GrayTableView.h"
#import "SongtrainProtocol.h"
#import "NSMutableArray+Playlist.h"

#import "TDAudioStreamer.h"

@interface PlaylistViewController : UIViewController <CurrentSongViewDelegate, MPMediaPickerControllerDelegate, UITableViewDelegate, UITableViewDataSource, MCSessionDelegate, SongtrainProtocolDelegate>{
    
    MPMediaPickerController *picker;
    
    NSMutableArray *playlist;
    
    CurrentSongView *albumArtwork;
    InfoViewController *infoView;
    GrayTableView *mainTableView;
    
    UIButton *addToList;
    
    MCSession *mainSession;
    MCPeerID *pid;
    NSString *service;
    
    SongtrainProtocol *trainProtocol;
}

- (instancetype)initWithSession:(MCSession*)session;

@end
