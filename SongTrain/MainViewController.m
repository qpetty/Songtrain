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
    CGRect songLocation = CGRectMake(self.navigationController.navigationBar.bounds.origin.x,
                                     self.navigationController.navigationBar.bounds.origin.y + self.navigationController.navigationBar.bounds.size.height + [[UIApplication sharedApplication]statusBarFrame].size.height,
                                     self.view.bounds.size.width,
                                     ARTWORK_HEIGHT);
    
    self.albumArtwork = [[CurrentSongView alloc] initWithSong:currentSong andFrame:songLocation];
    self.albumArtwork.delegate = self;
    [self.view addSubview:self.albumArtwork];
    [self progressUpdate];
    
    //Subscribe to changes of the musicPlayer to update song info
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(nowPlayingItemChanged:) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:musicPlayer];
    [notificationCenter addObserver:self selector:@selector(playbackStateChanged:) name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:musicPlayer];
    [musicPlayer beginGeneratingPlaybackNotifications];
    
    [self setProgressTimer];
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
@end
