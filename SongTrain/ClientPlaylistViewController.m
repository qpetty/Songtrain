//
//  ClientPlaylistViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 2/2/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "ClientPlaylistViewController.h"

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

- (instancetype)initWithSession:(MCSession*)session andServerPeerID:(MCPeerID*)peerID
{
    if (self = [super initWithSession:session]) {
        serverID = peerID;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    picker.delegate = self;
	// Do any additional setup after loading the view.
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:YES];
    //[mainSession disconnect];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    NSMutableArray *songRequests = [[NSMutableArray alloc] init];
    
    for (MPMediaItem *item in mediaItemCollection.items){
        Song *oneSong = [[Song alloc] init];
        oneSong.title = [item valueForProperty:MPMediaItemPropertyTitle];
        oneSong.artistName = [item valueForProperty:MPMediaItemPropertyArtist];
        oneSong.host = pid;
        oneSong.media = item;
        [songRequests addObject:oneSong];
    }
    
    NSLog(@"Sending some data\n");
    NSData *dataToSend = [NSKeyedArchiver archivedDataWithRootObject:songRequests];
    [mainSession sendData:dataToSend toPeers:[NSArray arrayWithObject:serverID] withMode:MCSessionSendDataReliable error:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnecting) {
        //Loading Icon
        NSLog(@"Connecting to %@", peerID.displayName);
    } else if (state == MCSessionStateConnected) {
        //Start stream
        NSLog(@"Connected to %@", peerID.displayName);
    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"Disconnected from %@", peerID.displayName);
        dispatch_async(dispatch_get_main_queue(), ^{
            [mainSession disconnect];
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSLog(@"Recieved some data\n");
    //NSLog(@"Playlist before data size: %d\n", playlist.count);
    playlist = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    //NSLog(@"Playlist size after data: %d\n", playlist.count);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainTableView reloadData];
    });
}

@end
