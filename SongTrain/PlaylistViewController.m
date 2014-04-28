//
//  PlaylistViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 1/26/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "PlaylistViewController.h"
#import "Animator.h"

@interface PlaylistViewController ()

@end


@implementation PlaylistViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        NSLog(@"Delegates for music player and session manager will be set\n");
        musicPlayer = [QPMusicPlayerController musicPlayer];
        musicPlayer.delegate = self;
        sessionManager = [QPSessionManager sessionManager];
        sessionManager.delegate = self;
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
    
    albumArtwork = [[CurrentSongView alloc] initWithFrame:location];
    [self.view addSubview:albumArtwork];
    
    // Tracks and Passengers selector background
    tableviewMenuBackground = [[UIView alloc] initWithFrame:CGRectMake(location.origin.x, location.origin.y + location.size.height, self.view.frame.size.width, 44)];

    tableviewMenuBackground.backgroundColor = UIColorFromRGBWithAlpha(0x464646, 0.67);
    [tableviewMenuBackground.layer setBorderWidth:0.0f];
    [tableviewMenuBackground.layer setBorderColor:UIColorFromRGBWithAlpha(0x252525, 0.7).CGColor];
    [self.view addSubview:tableviewMenuBackground];
    
    // Tracks and Passengers selector
    tableviewMenu = [[UISegmentedControl alloc] initWithItems:@[@"Tracks", @"Passengers"]];
    tableviewMenu.frame = CGRectMake(self.view.bounds.origin.x + 3, albumArtwork.frame.origin.y + albumArtwork.frame.size.height + 7, self.view.bounds.size.width - 6, 26);
    
    [tableviewMenu setSelectedSegmentIndex:0];
    [tableviewMenu setTintColor:UIColorFromRGB(0x6F95D3)];
    [self.view addSubview:tableviewMenu];
    

    [tableviewMenu addTarget:self action:@selector(tracksAndPassengersSegment) forControlEvents:UIControlEventValueChanged];
    
    //Initialize Media picker
    picker = [[MusicPickerViewController alloc] init];
    picker.delegate = self;
    
    //Create TableView
    location = CGRectMake(self.view.bounds.origin.x,
                          tableviewMenuBackground.frame.origin.y + tableviewMenuBackground.frame.size.height,
                          self.view.bounds.size.width,
                          self.view.bounds.size.height - (2 * albumArtwork.frame.origin.y) - albumArtwork.frame.size.height - tableviewMenuBackground.frame.size.height);
    mainTableView = [[GrayTableView alloc] initWithFrame:location];
    mainTableView.delegate = self;
    mainTableView.dataSource = self;
    [self.view addSubview:mainTableView];

    //Add Control Bar at bottom of the screen

    location = CGRectMake(mainTableView.frame.origin.x,
                          mainTableView.frame.origin.y + mainTableView.frame.size.height,
                          self.view.frame.size.width,
                          albumArtwork.frame.origin.y);
     
    panel = [[ControlPanel alloc] initWithFrame:location];
    panel.delegate = self;
    [self.view addSubview:panel];

    // Allow musicplayercontroller to update control panel
    musicPlayer.panel = panel;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [sessionManager addObserver:self forKeyPath:@"connectedPeersArray" options:NSKeyValueObservingOptionNew context:nil];
    [musicPlayer addObserver:self forKeyPath:@"currentSong" options:NSKeyValueObservingOptionNew context:nil];
    [musicPlayer addObserver:self forKeyPath:@"currentlyPlaying" options:NSKeyValueObservingOptionNew context:nil];
    [musicPlayer addObserver:self forKeyPath:@"currentSongTime" options:NSKeyValueObservingOptionNew context:nil];
    
    panel.isPlaying = musicPlayer.currentlyPlaying;
    [albumArtwork updateSongInfo:musicPlayer.currentSong];
    [mainTableView reloadData];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [sessionManager removeObserver:self forKeyPath:@"connectedPeersArray"];
    [musicPlayer removeObserver:self forKeyPath:@"currentSong"];
    [musicPlayer removeObserver:self forKeyPath:@"currentlyPlaying"];
    [musicPlayer removeObserver:self forKeyPath:@"currentSongTime"];
}

- (void)tracksAndPassengersSegment
{
    [mainTableView reloadData];
}

- (void)addToPlaylist
{
    [self.navigationController presentViewController:picker animated: YES completion:nil];
}

- (void)buttonPressed:(UIButton *)sender
{
    if (sender.tag == AddButton) {
        [self addToPlaylist];
    }
    else if (sender.tag == PlayButton && sessionManager.currentRole == ServerConnection) {
        [musicPlayer play];
    }
    else if (sender.tag == SkipButton) {
        [musicPlayer skip];
    }
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
}


- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"Peer cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.backgroundColor = UIColorFromRGBWithAlpha(0x464646, 0.3);
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.userInteractionEnabled = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if (tableviewMenu.selectedSegmentIndex) {
        
        if (sessionManager.connectedPeersArray.count) {
            cell.textLabel.text = [[sessionManager.connectedPeersArray objectAtIndex:[indexPath row]] displayName];
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = @"No Passengers in Train";
            cell.detailTextLabel.text = @"";
        }
        return cell;
    }
    if (musicPlayer.playlist.count){
        cell.textLabel.text = [[musicPlayer.playlist objectAtIndex:[indexPath row]] title];
        cell.detailTextLabel.text = [[musicPlayer.playlist objectAtIndex:[indexPath row]] artistName];
    }
    else{
        cell.textLabel.text = @"No Songs in Queue";
        cell.detailTextLabel.text = @"";
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 48;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableviewMenu.selectedSegmentIndex) {
        return sessionManager.peerArray.count > 1 ? sessionManager.peerArray.count - 1 : 1;
    }

    return musicPlayer.playlist.count ? musicPlayer.playlist.count : 1;
}

- (void)connectedToPeer:(MCPeerID *)peerID
{
    
}

- (void)disconnectedFromPeer:(MCPeerID *)peerID
{
    
}

- (void)playListHasBeenUpdated
{
    NSLog(@"Updating Playlist\n");
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainTableView reloadData];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (object == musicPlayer && [keyPath isEqualToString:@"currentSongTime"]) {
            [panel setSongDuration:musicPlayer.currentSongTime];
        }
        else if (object == musicPlayer && [keyPath isEqualToString:@"currentlyPlaying"]) {
            panel.isPlaying = musicPlayer.currentlyPlaying;
        }
        else if (object == musicPlayer && [keyPath isEqualToString:@"currentSong"]) {
            [albumArtwork updateSongInfo:musicPlayer.currentSong];
            [mainTableView reloadData];
        }
        else {
            [mainTableView reloadData];
        }
    });
}

@end
