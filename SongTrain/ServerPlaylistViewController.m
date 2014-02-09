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
    if ([musicPlayer nowPlayingItem]){
        [playlist addSongFromMediaItemToList:[musicPlayer nowPlayingItem] withPeerID:pid];
    }
    
    //Broadcast Train to others
    
    advert = [[MCNearbyServiceAdvertiser alloc] initWithPeer:pid discoveryInfo:nil serviceType:service];
    advert.delegate = self;
    
    picker.delegate = self;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:YES error:nil];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    
    NSURL *assetURL = [NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"TheFuneral" ofType:@"m4a"]];
    player = [[MusicQueuePlayer alloc] initWithUrl:assetURL];
    //[player play];
    //[player getAudioFromFile:[[playlist firstObject] media]];
    
    //[self getAudioFromFile: [[playlist firstObject] media]];
}

-(void)viewWillAppear:(BOOL)animated
{
    NSLog(@"Advertising Peers...\n");
    [advert startAdvertisingPeer];

    /*
    const char *here = "somehting";
     
    dispatch_async(dispatch_queue_create(here, NULL),^{
        [self getAudioFromFile: [[playlist firstObject] media]];
    });
     */
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
        [playlist addSongFromMediaItemToList:item withPeerID:pid];
    }
    
    NSLog(@"Sending some data\n");

    //NSData *dataToSend = [NSKeyedArchiver archivedDataWithRootObject:playlist];
    [mainSession sendData:[SongtrainProtocol dataFromSongArray:playlist] toPeers:mainSession.connectedPeers withMode:MCSessionSendDataReliable error:nil];
    
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
            [mainSession sendData:[SongtrainProtocol dataFromSongArray:playlist] toPeers:[NSArray arrayWithObject:peerID] withMode:MCSessionSendDataReliable error:nil];
        }
    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"Disconnected from %@", peerID.displayName);
        //Remove songs from disconnected peer
        int i = 0;
        while (i < playlist.count) {
            //NSLog(@"Looking at song: %@", [playlist objectAtIndex:i]);
            //NSLog(@"Host is: %@", [[playlist objectAtIndex:i] host]);
            if ([peerID.displayName isEqualToString:[ (MCPeerID*)[[playlist objectAtIndex:i] host] displayName]]) {
                [playlist removeObjectAtIndex:i];
            }
            else{
                i++;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [mainTableView reloadData];
        });
    }
}

-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    if (audioInStream) {
        [audioInStream stop];
    }
    audioInStream = [[TDAudioInputStreamer alloc] initWithInputStream:stream];
    [audioInStream start];
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    [trainProtocol messageToParse:data];
}

- (void)receivedSongArray:(NSMutableArray*)songArray
{
    for (Song *one in songArray) {
        [playlist addObject:one];
    }
    NSLog(@"Sending ACK from server\n");
    
    [mainSession sendData:[SongtrainProtocol dataFromSongArray:playlist] toPeers:mainSession.connectedPeers withMode:MCSessionSendDataReliable error:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainTableView reloadData];
    });
}

- (void)finishedPlayingSong
{
    [playlist removeObjectAtIndex:0];
    NSURL *nextURL = [[[playlist objectAtIndex:0] media] valueForProperty:MPMediaItemPropertyAssetURL];
    NSArray *nextPeer = [NSArray arrayWithObjects:[[playlist objectAtIndex:0] host], nil];
    [mainSession sendData:[SongtrainProtocol dataFromURL: nextURL] toPeers: nextPeer withMode:MCSessionSendDataReliable error:nil];
}

@end
