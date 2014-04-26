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
#import "GrayTableView.h"
#import "ControlPanel.h"

#import "NSMutableArray+Playlist.h"
#import "QPMusicPlayerController.h"
#import "QPSessionManager.h"

#import "TDAudioStreamer.h"

#import "MusicPickerViewController.h"

@interface PlaylistViewController : UIViewController <ControlPanelDelegate, MPMediaPickerControllerDelegate, UITableViewDelegate, UITableViewDataSource, QPSessionManagerDelegate, QPMusicPlayerControllerDelegate, MusicPickerViewController>{
    
    //MPMediaPickerController *picker;
    MusicPickerViewController *picker;
    
    QPMusicPlayerController *musicPlayer;
    QPSessionManager *sessionManager;
    
    CurrentSongView *albumArtwork;
    GrayTableView *mainTableView;
    ControlPanel *panel;
    UISegmentedControl *tableviewMenu;
    UIView* tableviewMenuBackground;
    
    UIButton *addToList;
}

@end
