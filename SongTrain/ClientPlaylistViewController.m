//
//  ClientPlaylistViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 2/2/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "ClientPlaylistViewController.h"
#import "QPMusicPlayerController.h"
#import "QPSessionManager.h"

@interface ClientPlaylistViewController ()

@end

@implementation ClientPlaylistViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    //TODO: Send song to server
    
    NSLog(@"Sending some data\n");
    
    for (MPMediaItem *item in mediaItemCollection.items) {
        LocalSong *tempSong = [[LocalSong alloc] initWithOutputASBD:*(musicPlayer.audioFormat) andItem:item];
        [sessionManager addSongToServer:tempSong];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)connectedToPeer:(MCPeerID *)peerID
{
    //musicPlayer resetMusicPlayer];
}

- (void)disconnectedFromPeer:(MCPeerID *)peerID
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popToRootViewControllerAnimated:YES];
    });
}

@end
