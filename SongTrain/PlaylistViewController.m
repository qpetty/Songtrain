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
    albumArtwork.delegate = self;
    [self.view addSubview:albumArtwork];
    
    //Initialize Media picker
    picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    picker.allowsPickingMultipleItems = YES;
    picker.prompt = NSLocalizedString (@"Add songs to play", "Prompt in media item picker");
    
    //Create an Add button
    CGRect buttonLocation = CGRectMake(albumArtwork.frame.origin.x,
                          albumArtwork.frame.origin.y + albumArtwork.frame.size.height,
                          50,
                          30);
    
    addToList = [[UIButton alloc] initWithFrame:buttonLocation];
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

    /*
    musicPlayer = [QPMusicPlayerController musicPlayer];
    musicPlayer.delegate = self;
    sessionManager = [QPSessionManager sessionManager];
    sessionManager.delegate = self;
     */
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[sessionManager stopBrowsing];
}

- (void)addToPlaylist
{
    [self.navigationController presentViewController:picker animated: YES completion:nil];
}

- (void)buttonPressed:(UIButton*)sender withSong:(Song *)song
{
    if (sender.tag == InfoButton) {
        NSLog(@"Info Button pressed\n");
        //TODO: Memory allocation, only want one InfoViewController
        if (!infoView)
            infoView = [[InfoViewController alloc] initWithSong:song];
        [self.navigationController pushViewController:infoView animated:YES];
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        cell.backgroundColor = UIColorFromRGB(0x464646);
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    if (musicPlayer.playlist.count){
        cell.textLabel.text = [[musicPlayer.playlist objectAtIndex:[indexPath row]] title];
        cell.detailTextLabel.text = [[musicPlayer.playlist objectAtIndex:[indexPath row]] artistName];
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
    [infoView updateSong:[musicPlayer.playlist objectAtIndex:[indexPath row]]];
    [self.navigationController pushViewController:infoView animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(musicPlayer.playlist.count)
        return musicPlayer.playlist.count;
    return 1;
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
@end
