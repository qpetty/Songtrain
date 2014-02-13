//
//  ServerPlaylistViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 2/2/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "ServerPlaylistViewController.h"
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

    // Add Dj button for host, I think that's the only person who should have it, right?
    // TODO: reposition the dj button, alter size, ui changes and what not
    location = CGRectMake(self.view.frame.size.width - self.navigationController.navigationBar.frame.size.width / 8,
                          self.navigationController.navigationBar.frame.size.height / 7,                                 BUTTON_SIZE, BUTTON_SIZE);
    djButton = [[UIButton alloc] initWithFrame:location];
    [self.navigationController.navigationBar addSubview:djButton];
    [djButton setContentMode:UIViewContentModeScaleAspectFit];

    [djButton setImage:[UIImage imageNamed:@"dj_click"] forState:UIControlStateNormal];
    [djButton setImage:[UIImage imageNamed:@"dj_inactive"] forState:UIControlStateSelected];

    //[djButton addTarget:self.delegate action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
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
    NSLog(@"Received Stream: %@\n", streamName);
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

- (void)playNextSong
{
    if (!playlist.count) {
        //No songs in list
        return;
    }
    
    NSLog(@"Trying to play the next song\n");
    
    Song *nextSong = [playlist firstObject];
    
    if (audioPlayer){
        [audioPlayer stop];
        audioPlayer = nil;
    }
    
    if (audioInStream){
        [audioInStream pause];
        [audioInStream stop];
        audioInStream = nil;
    }

    if ([nextSong.host.displayName isEqualToString:[pid displayName]]) {
        
        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[nextSong media] valueForProperty:MPMediaItemPropertyAssetURL] error:nil];
        audioPlayer.delegate = self;
        [audioPlayer play];
        
        NSLog(@"Sending meida item: %@\n", nextSong.media);
        NSLog(@"URL of item: %@\n", [nextSong.media valueForProperty:MPMediaItemPropertyAssetURL]);
        
        NSLog(@"Beginning Local Song\n");
    }
    else{
        NSArray *nextPeer = [NSArray arrayWithObjects:nextSong.host, nil];
        [mainSession sendData:[SongtrainProtocol dataFromMedia: nextSong] toPeers: nextPeer withMode:MCSessionSendDataReliable error:nil];
        NSLog(@"Playing Song from %@\n", nextSong.host.displayName);
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self finishedPlayingSong];
}

- (void)pause
{
    if (audioPlayer)
        [audioPlayer pause];
    else if (audioInStream)
        [audioInStream pause];
}

- (void)resume
{
    if (audioPlayer)
        [audioPlayer play];
    else if (audioInStream)
        [audioInStream resume];
}

- (void)finishedPlayingSong
{
    [playlist removeObjectAtIndex:0];
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainTableView reloadData];
    });
    [self playNextSong];
}

@end
