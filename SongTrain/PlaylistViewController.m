//
//  PlaylistViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 1/26/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "PlaylistViewController.h"

@interface PlaylistViewController ()

@end

@implementation PlaylistViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithPlaylistFunction:(int)playlistFunction
{
    if (self = [super init]) {
        if (playlistFunction == Host)
            isHost = YES;
        else
            isHost = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.backgroundColor = UIColorFromRGB(0x363636);
    
    //Create Song View at top of view
    CGRect location = CGRectMake(self.navigationController.navigationBar.bounds.origin.x,
                                 self.navigationController.navigationBar.bounds.origin.y + self.navigationController.navigationBar.bounds.size.height + [[UIApplication sharedApplication]statusBarFrame].size.height,
                                 self.view.bounds.size.width,
                                 ARTWORK_HEIGHT);
    
    musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    playlist = [[NSMutableArray alloc] init];
    
    albumArtwork = [[CurrentSongView alloc] initWithFrame:location];
    albumArtwork.delegate = self;
    [self.view addSubview:albumArtwork];
    
    //Initialize Media picker
    picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    picker.delegate = self;
    picker.allowsPickingMultipleItems = YES;
    picker.prompt = NSLocalizedString (@"Add songs to play", "Prompt in media item picker");
    
    //Create an Add button
    location = CGRectMake(albumArtwork.frame.origin.x,
                          albumArtwork.frame.origin.y + albumArtwork.frame.size.height,
                          50,
                          30);
    
    addToList = [[UIButton alloc] initWithFrame:location];
    [addToList setTitle:@"Add" forState:UIControlStateNormal];
    [addToList addTarget:self action:@selector(addToPlaylist) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:addToList];
    
    //Create TableView
    location = CGRectMake(self.view.bounds.origin.x,
                          location.origin.y + location.size.height + 40,
                          self.view.bounds.size.width,
                          self.view.bounds.size.height - location.origin.y - location.size.height - 40);
    mainTableView = [[GrayTableView alloc] initWithFrame:location];
    mainTableView.delegate = self;
    mainTableView.dataSource = self;
    [self.view addSubview:mainTableView];
    
    if (isHost) {
        musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
        [albumArtwork addPlayer:musicPlayer];
        
        //Add whole queue instead of single song
        if ([musicPlayer nowPlayingItem])
            [playlist addObject:[musicPlayer nowPlayingItem]];
        //Broadcast Train to others
        service = @"SoundTrain";
        pid = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
        
        mainSession = [[MCSession alloc] initWithPeer:pid];
        mainSession.delegate = self;
    
        advert = [[MCNearbyServiceAdvertiser alloc] initWithPeer:pid discoveryInfo:nil serviceType:service];
        advert.delegate = self;
    }
    else{
        NSLog(@"Client\n");
    }
    
    //Subscribe to changes of the musicPlayer
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(nowPlayingItemChanged:) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:musicPlayer];
    //[notificationCenter addObserver:self selector:@selector(playbackStateChanged:) name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:musicPlayer];
    [musicPlayer beginGeneratingPlaybackNotifications];
    
    [mainTableView reloadData];
}

- (void)nowPlayingItemChanged:(id)sender
{
    while (playlist.count > 0 && [playlist firstObject] != [musicPlayer nowPlayingItem]) {
        [playlist removeObjectAtIndex:0];
    }
    [mainTableView reloadData];
}

- (void)playbackStateChanged:(id)sender
{
}

- (void)addToPlaylist
{
    [self.navigationController presentViewController:picker animated: YES completion:nil];
}

- (void)buttonPressed:(UIButton*)sender
{
    if (sender.tag == InfoButton) {
        NSLog(@"Info Button pressed\n");
        //TODO: Memory allocation, only want one InfoViewController
        if (!infoView)
            infoView = [[InfoViewController alloc] initWithPlayer:musicPlayer];
        [self.navigationController pushViewController:infoView animated:YES];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"Peer cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        cell.backgroundColor = UIColorFromRGB(0x464646);
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    if (playlist.count > 0){
        cell.textLabel.text = [[playlist objectAtIndex:[indexPath row]] valueForProperty:MPMediaItemPropertyTitle];
        cell.detailTextLabel.text = [[playlist objectAtIndex:[indexPath row]] valueForProperty:MPMediaItemPropertyArtist];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.userInteractionEnabled = YES;
    }
    else{
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.userInteractionEnabled = NO;
        cell.textLabel.text = @"No Songs in Queue";
        cell.detailTextLabel.text = @"";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selected: %@\n", [tableView cellForRowAtIndexPath:indexPath].textLabel.text);
    
    if (!infoView)
        infoView = [[InfoViewController alloc] init];
    [infoView updateSong:[playlist objectAtIndex:[indexPath row]]];
    [self.navigationController pushViewController:infoView animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(playlist.count > 0)
        return playlist.count;
    return 1;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    [self updateQueueWithCollection:mediaItemCollection];
    [self dismissViewControllerAnimated:YES completion:nil];
    [mainTableView reloadData];
}


- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//Has a quick delay when new song are added and sound turns off after the 2nd addition
- (void) updateQueueWithCollection: (MPMediaItemCollection *) collection
{
    
    // Add 'collection' to the music player's playback queue, but only if
    //    the user chose at least one song to play.
    if (collection) {
        BOOL wasPlaying = NO;
        if (musicPlayer.playbackState == MPMusicPlaybackStatePlaying) {
            wasPlaying = YES;
        }
        
        // Save the now-playing item and its current playback time.
        MPMediaItem *nowPlayingItem        = musicPlayer.nowPlayingItem;
        NSTimeInterval currentPlaybackTime = musicPlayer.currentPlaybackTime;
        
        for (MPMediaItem *item in collection.items)
            [playlist addObject:item];
        
        if (playlist.count) {
            currentPlaylist = [MPMediaItemCollection collectionWithItems:(NSArray *) playlist];
            [musicPlayer setQueueWithItemCollection: currentPlaylist];
        }

        // Restore the now-playing item and its current playback time.
        musicPlayer.nowPlayingItem      = nowPlayingItem;
        musicPlayer.currentPlaybackTime = currentPlaybackTime;
        if (wasPlaying) {
            [musicPlayer play];
        }

    }
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

    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"Disconnected from %@", peerID.displayName);
    }
}

-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    
}

-(void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    
}

-(void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    
}

@end
