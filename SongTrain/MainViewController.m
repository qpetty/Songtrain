//
//  ViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 1/21/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    //Construct User Interface
    
    self.view.backgroundColor = UIColorFromRGB(0x363636);
    
    //Sets up the navigationBar to be transparent, same as Background Image
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:UIColorFromRGB(0xebebeb), NSForegroundColorAttributeName, nil];
    [self setTitle:@"Songtrain"];
    
    //Get current playing song
    musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    currentSong = [musicPlayer nowPlayingItem];
    
    //Insert Song View in the created CGRect
    CGRect location = CGRectMake(self.navigationController.navigationBar.bounds.origin.x,
                                     self.navigationController.navigationBar.bounds.origin.y + self.navigationController.navigationBar.bounds.size.height + [[UIApplication sharedApplication]statusBarFrame].size.height,
                                     self.view.bounds.size.width,
                                     ARTWORK_HEIGHT);
    
    self.albumArtwork = [[CurrentSongView alloc] initWithSong:currentSong andFrame:location];
    self.albumArtwork.delegate = self;
    [self.view addSubview:self.albumArtwork];
    [self progressUpdate];
    
    
    //Subscribe to changes of the musicPlayer to update song info
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(nowPlayingItemChanged:) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:musicPlayer];
    [notificationCenter addObserver:self selector:@selector(playbackStateChanged:) name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:musicPlayer];
    [musicPlayer beginGeneratingPlaybackNotifications];
    
    [self setProgressTimer];
    
    //Setup create train button
    location = CGRectMake(self.view.bounds.origin.x,
                                       location.origin.y + location.size.height + 40,
                                       self.view.bounds.size.width,
                                       50);
    self.createTrainButton = [[SingleCellButton alloc] initWithFrame:location];
    [self.view addSubview:self.createTrainButton];
    [self.createTrainButton setTitle:@"Create New Train" forState:UIControlStateNormal];
    [self.createTrainButton addTarget:self action:@selector(createTrainPressed:) forControlEvents:UIControlEventTouchDown];
    
    //Create TableView
    location = CGRectMake(self.view.bounds.origin.x,
                          location.origin.y + location.size.height + 40,
                          self.view.bounds.size.width,
                          self.view.bounds.size.height - location.origin.y - location.size.height - 40);
    mainTableView = [[GrayTableView alloc] initWithFrame:location];
    [self.view addSubview:mainTableView];
    [mainTableView reloadData];
    
    
    //TableView Title
    location = CGRectMake(self.view.bounds.origin.x + 15,
                          location.origin.y - 20,
                          self.view.bounds.size.width,
                          14);
    label = [[UILabel alloc] initWithFrame:location];
    label.textColor = [UIColor whiteColor];
    [label setFont:[UIFont systemFontOfSize:12]];
    label.text = @"TRAINS";
    
    [self.view addSubview:label];
    
    //Multipeer Connectivity initialization
    service = @"SoundTrain";
    pid = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    
    peerArray = [[NSMutableArray alloc] init];
    mainTableView.dataSource = self;
    mainTableView.delegate = self;
    
    session = [[MCSession alloc] initWithPeer:pid];
    session.delegate = self;
    
    browse = [[MCNearbyServiceBrowser alloc] initWithPeer:pid serviceType:service];
    browse.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"Browsing for Peers...\n");
    [browse startBrowsingForPeers];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"View did appear...\n");
    [self.albumArtwork updateSongInfo:[musicPlayer nowPlayingItem]];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSLog(@"Stopped browsing for Peers...\n");
    [browse stopBrowsingForPeers];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSLog(@"View did Disappear...\n");
    [progressTimer invalidate];
    progressTimer = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setProgressTimer{
    progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(progressUpdate) userInfo:nil repeats:YES];
}

- (void)progressUpdate
{
    [self.albumArtwork updateProgressBar:musicPlayer.currentPlaybackTime];
}

- (void)nowPlayingItemChanged:(id)sender
{
    [self.albumArtwork updateSongInfo:[musicPlayer nowPlayingItem]];
    [self progressUpdate];
}

- (void)playbackStateChanged:(id)sender
{

    MPMusicPlaybackState playbackState = [musicPlayer playbackState];
    
    
    if (playbackState == MPMusicPlaybackStatePlaying){
        if (!progressTimer) {
            [self setProgressTimer];
        }
    }
    else{
        [progressTimer invalidate];
        progressTimer = nil;
    }
}

- (void)createTrainPressed:(UIButton*)sender
{
    NSLog(@"Create new Train\n");
}

- (void)buttonPressed:(UIButton*)sender
{
    if (sender.tag == InfoButton) {
        NSLog(@"Info Button pressed\n");
    }
    else if (sender.tag == FavoriteButton) {
        NSLog(@"Favorite Button pressed\n");
    }
    else if (sender.tag == MuteButton) {
        NSLog(@"Mute Button pressed\n");
        
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"peerCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] init];
        cell.backgroundColor = UIColorFromRGB(0x464646);
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    if (peerArray.count > 0){
        cell.textLabel.text = [[peerArray objectAtIndex:[indexPath row]] displayName];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.userInteractionEnabled = YES;
    }
    else{
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.userInteractionEnabled = NO;
        cell.textLabel.text = @"No Nearby Trains";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selected train: %@\n", [tableView cellForRowAtIndexPath:indexPath].textLabel.text);
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(peerArray.count > 0)
        return peerArray.count;
    else
        return 1;
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSLog(@"Found Peer: %@", peerID.displayName);
    if (![peerID.displayName isEqualToString:pid.displayName]) {
        NSLog(@"Added Peer: %@", peerID.displayName);
        [peerArray addObject:peerID];
        [mainTableView reloadData];
    }
}

-(void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"Lost Peer: %@", peerID.displayName);
    if (![peerID.displayName isEqualToString:pid.displayName]) {
        NSLog(@"Removed Peer: %@", peerID.displayName);
        [peerArray removeObjectIdenticalTo:peerID];
        [mainTableView reloadData];
    }
}

-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnecting) {
        NSLog(@"Connecting to %@", peerID.displayName);
    } else if (state == MCSessionStateConnected) {
        NSLog(@"Connected to %@", peerID.displayName);
    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"Disconnected from %@", peerID.displayName);
    }
}

-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"Got Stream: %@  from %@\n", streamName, [peerID displayName]);
}

-(void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    
}

-(void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSLog(@"Here: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}
@end
