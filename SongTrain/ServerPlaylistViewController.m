//
//  ServerPlaylistViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 2/2/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "ServerPlaylistViewController.h"
#import "QPMusicPlayerController.h"
#import "QPSessionManager.h"

#define BUTTON_SIZE 30

@interface ServerPlaylistViewController ()

@end

@implementation ServerPlaylistViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    picker.delegate = self;
    
    CGRect location = CGRectMake(0, albumArtwork.frame.origin.y + albumArtwork.frame.size.height, 50, 50);
    
    playButton = [[UIButton alloc] initWithFrame:location];
    [playButton setTitle:@"Play" forState:UIControlStateNormal];
    [playButton addTarget:musicPlayer action:@selector(play) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:playButton];
    
    // Add Dj button for host, I think that's the only person who should have it, right?
    // TODO: reposition the dj button, alter size, ui changes and what not
    location = CGRectMake(self.view.frame.size.width - self.navigationController.navigationBar.frame.size.width / 8,
                          self.navigationController.navigationBar.frame.size.height / 7, BUTTON_SIZE, BUTTON_SIZE);
    djButton = [[UIButton alloc] initWithFrame:location];
    [self.navigationController.navigationBar addSubview:djButton];
    [djButton setContentMode:UIViewContentModeScaleAspectFit];

    [djButton setImage:[UIImage imageNamed:@"dj_click"] forState:UIControlStateNormal];
    [djButton setImage:[UIImage imageNamed:@"dj_inactive"] forState:UIControlStateSelected];

    //[djButton addTarget:self.delegate action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
    
    [albumArtwork updateSongInfo:musicPlayer.currentSong];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    djButton.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    djButton.hidden = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    [musicPlayer addSongsToPlaylist:mediaItemCollection];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)connectedToPeer:(MCPeerID *)peerID
{
    //NSLog(@"connectedToPeer");
    if (musicPlayer.playlist.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [sessionManager sendData:[SongtrainProtocol dataFromSongArray:musicPlayer.playlist] ToPeer:peerID];
        });
    }
}

- (void)disconnectedFromPeer:(MCPeerID*)peerID
{
    //[musicPlayer removeSongsWithPeerID:peerID];
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainTableView reloadData];
    });
}

@end
