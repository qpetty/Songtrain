//
//  ServerPlaylistViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 2/2/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "ServerPlaylistViewController.h"

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
    
    musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    [albumArtwork addPlayer:musicPlayer];
    
    //Add whole queue instead of single song
    //if ([musicPlayer nowPlayingItem])
        //[playlist addObject:[musicPlayer nowPlayingItem]];
    //Broadcast Train to others
    
    advert = [[MCNearbyServiceAdvertiser alloc] initWithPeer:pid discoveryInfo:nil serviceType:service];
    advert.delegate = self;
    
    picker.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated
{
    NSLog(@"Advertising Peers...\n");
    [advert startAdvertisingPeer];
}

-(void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"Stopped Advertising Peers...\n");
    [advert stopAdvertisingPeer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    //[self updateQueueWithCollection:mediaItemCollection];
    
    for (MPMediaItem *item in mediaItemCollection.items){
        Song *oneSong = [[Song alloc] init];
        oneSong.title = [item valueForProperty:MPMediaItemPropertyTitle];
        oneSong.artistName = [item valueForProperty:MPMediaItemPropertyArtist];
        [playlist addObject:oneSong];
    }
    
    NSLog(@"Sending some data\n");

    NSData *dataToSend = [NSKeyedArchiver archivedDataWithRootObject:playlist];
    [mainSession sendData:dataToSend toPeers:mainSession.connectedPeers withMode:MCSessionSendDataReliable error:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [mainTableView reloadData];
}

-(void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{
    NSLog(@"Got Invite from %@", peerID.displayName);
    invitationHandler(YES,mainSession);
}

-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnecting) {
        //Loading Icon
        NSLog(@"Connecting to %@", peerID.displayName);
    } else if (state == MCSessionStateConnected) {
        //Start stream
        NSLog(@"Connected to %@", peerID.displayName);
        if (playlist.count) {
            NSData *dataToSend = [NSKeyedArchiver archivedDataWithRootObject:playlist];
            [mainSession sendData:dataToSend toPeers:[NSArray arrayWithObject:peerID] withMode:MCSessionSendDataReliable error:nil];
        }
    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"Disconnected from %@", peerID.displayName);
    }
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSMutableArray *songRequests = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    for (Song *one in songRequests) {
        [playlist addObject:one];
    }
    NSLog(@"Sending ACK from server\n");
    NSData *dataToSend = [NSKeyedArchiver archivedDataWithRootObject:playlist];
    [mainSession sendData:dataToSend toPeers:mainSession.connectedPeers withMode:MCSessionSendDataReliable error:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainTableView reloadData];
    });
}

@end
