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
    
    CGRect location = CGRectMake(addToList.frame.origin.x + 150, addToList.frame.origin.y, addToList.frame.size.width, addToList.frame.size.height);
    
    playButton = [[UIButton alloc] initWithFrame:location];
    [playButton setTitle:@"Play" forState:UIControlStateNormal];
    [playButton addTarget:self action:@selector(playNextSong) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:playButton];
    
    location = CGRectMake(addToList.frame.origin.x + 250, addToList.frame.origin.y, addToList.frame.size.width, addToList.frame.size.height);
    
    skipButton = [[UIButton alloc] initWithFrame:location];
    [skipButton setTitle:@"Skip" forState:UIControlStateNormal];
    [skipButton addTarget:self action:@selector(finishedPlayingSong) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:skipButton];
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
    [mainTableView reloadData];
}

- (void)connectedToPeer:(MCPeerID *)peerID
{
    if (musicPlayer.playlist.count) {
        [sessionManager sendData:[SongtrainProtocol dataFromSongArray:musicPlayer.playlist] ToPeer:peerID];
    }
}

- (void)disconnectedFromPeer:(MCPeerID*)peerID
{
    [musicPlayer removeSongsWithPeerID:peerID];
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainTableView reloadData];
    });
}

@end
