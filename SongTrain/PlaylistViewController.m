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

    //musicPlayer.nowPlayingItem = [[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem];
    //musicPlayer.currentPlaybackTime = [[MPMusicPlayerController iPodMusicPlayer] currentPlaybackTime];
    
    //[musicPlayer setQueueWithItemCollection:currentPlaylist];
    albumArtwork = [[CurrentSongView alloc] initWithPlayer:musicPlayer andFrame:location];
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
    [mainTableView reloadData];
}

- (void)addToPlaylist
{
    /*
    picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    picker.delegate = self;
    picker.allowsPickingMultipleItems = YES;
    picker.prompt = NSLocalizedString (@"Add songs to play", "Prompt in media item picker");
     */
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
    if (currentPlaylist.count > 0){
        cell.textLabel.text = [[currentPlaylist.items objectAtIndex:[indexPath row]] valueForProperty:MPMediaItemPropertyTitle];
        cell.detailTextLabel.text = [[currentPlaylist.items objectAtIndex:[indexPath row]] valueForProperty:MPMediaItemPropertyArtist];
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(currentPlaylist.count > 0)
        return currentPlaylist.count;
    else
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

//From Apple's Docs
- (void) updateQueueWithCollection: (MPMediaItemCollection *) collection {
    
    // Add 'collection' to the music player's playback queue, but only if
    //    the user chose at least one song to play.
    if (collection) {
        
        // If there's no playback queue yet...
        if (currentPlaylist == nil) {
            currentPlaylist = collection;
            [musicPlayer setQueueWithItemCollection: currentPlaylist];
            [musicPlayer play];
            
            // Obtain the music player's state so it can be restored after
            //    updating the playback queue.
        } else {
            BOOL wasPlaying = NO;
            if (musicPlayer.playbackState == MPMusicPlaybackStatePlaying) {
                wasPlaying = YES;
            }
            
            // Save the now-playing item and its current playback time.
            MPMediaItem *nowPlayingItem        = musicPlayer.nowPlayingItem;
            NSTimeInterval currentPlaybackTime = musicPlayer.currentPlaybackTime;
            
            // Combine the previously-existing media item collection with
            //    the new one
            NSMutableArray *combinedMediaItems = [[currentPlaylist items] mutableCopy];
            NSArray *newMediaItems = [collection items];
            [combinedMediaItems addObjectsFromArray: newMediaItems];
            
            currentPlaylist = [MPMediaItemCollection collectionWithItems:(NSArray *) combinedMediaItems];
            [musicPlayer setQueueWithItemCollection: currentPlaylist];
            
            // Restore the now-playing item and its current playback time.
            musicPlayer.nowPlayingItem      = nowPlayingItem;
            musicPlayer.currentPlaybackTime = currentPlaybackTime;
            
            if (wasPlaying) {
                [musicPlayer play];
            }
        }
    }
}

@end
