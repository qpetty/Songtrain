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
        oneSong.url = [item valueForProperty:MPMediaItemPropertyAssetURL];
        NSLog(@"Sending meida item: %@\n", oneSong.media);
        NSLog(@"URL of item: %@\n", [oneSong.media valueForProperty:MPMediaItemPropertyAssetURL]);
        [songRequests addObject:oneSong];
    }
    
    NSLog(@"Sending some data\n");
    
    [mainSession sendData:[SongtrainProtocol dataFromSongArray:songRequests] toPeers:[NSArray arrayWithObject:serverID] withMode:MCSessionSendDataReliable error:nil];
    
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
    [trainProtocol messageToParse:data];
}

- (void)receivedSongArray:(NSMutableArray*)songArray
{
    playlist = songArray;
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainTableView reloadData];
    });
}
- (void)requestToStartStreaming:(Song*)song
{
    if (audioOutStream) {
        [audioOutStream stop];
    }
    NSOutputStream *outStream = [mainSession startStreamWithName:@"one" toPeer:serverID error:nil];
    audioOutStream = [[TDAudioOutputStreamer alloc] initWithOutputStream:outStream];
    NSLog(@"Trying to play media item: %@\n", song.media);
    NSLog(@"URL of item: %@\n", [song.media valueForProperty:MPMediaItemPropertyAssetURL]);
    NSLog(@"URL from song: %@\n", song.url);
    [audioOutStream streamAudioFromURL:song.url];
    [audioOutStream start];
}
- (void)requestToStopStreaming
{
    if (audioOutStream) {
        [audioOutStream stop];
    }
}



@end
