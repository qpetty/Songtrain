//
//  PlaylistViewController.h
//  SongTrain
//
//  Created by Quinton Petty on 1/26/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "UsefulFunctions.h"
#import "CurrentSongView.h"
#import "InfoViewController.h"
#import "GrayTableView.h"
#import "ControlPanel.h"

#import "SongtrainProtocol.h"
#import "NSMutableArray+Playlist.h"
#import "QPMusicPlayerController.h"
#import "QPSessionManager.h"

#import "TDAudioStreamer.h"

@interface PlaylistViewController : UIViewController <CurrentSongViewDelegate, MPMediaPickerControllerDelegate, UITableViewDelegate, UITableViewDataSource, QPSessionManagerDelegate, QPMusicPlayerControllerDelegate>{
    
    MPMediaPickerController *picker;
    
    QPMusicPlayerController *musicPlayer;
    QPSessionManager *sessionManager;
    
    CurrentSongView *albumArtwork;
    InfoViewController *infoView;
    GrayTableView *mainTableView;
    ControlPanel *panel;
    
    UIButton *addToList;
}

@end
