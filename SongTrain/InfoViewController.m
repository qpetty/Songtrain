//
//  InfoViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 1/24/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "InfoViewController.h"

@interface InfoViewController ()

@end

@implementation InfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithPlayer:(MPMusicPlayerController*)player
{
    self = [super init];
    if(self) {
        mediaPlayer = player;
        currentSong = [player nowPlayingItem];
        self.title = @"Song Info";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = UIColorFromRGB(0x363636);
    
    UIBarButtonItem *btnBack = [[UIBarButtonItem alloc]
                                initWithTitle:@"Back"
                                style:UIBarButtonItemStyleBordered
                                target:self
                                action:nil];
    self.navigationController.navigationBar.topItem.backBarButtonItem = btnBack;
    
    //Add Album Artwork
    albumArtwork = [[UIImageView alloc] initWithFrame:CGRectMake(self.navigationController.navigationBar.bounds.origin.x,
                                                                 self.navigationController.navigationBar.bounds.origin.y + self.navigationController.navigationBar.bounds.size.height + [[UIApplication sharedApplication]statusBarFrame].size.height,
                                                                 self.view.bounds.size.width,
                                                                 ALBUM_SIZE)];
    [self updateArtwork];
    [self.view addSubview:albumArtwork];
    
    //Add Song information
    
    songView = [[CurrentSongView alloc] initWithFrame:CGRectMake(self.navigationController.navigationBar.bounds.origin.x,
                                                                                       albumArtwork.frame.origin.y + albumArtwork.frame.size.height,
                                                                                       self.view.frame.size.width,
                                                                                       SONG_INFO_HEIGHT)];
    [songView updateSongInfo:currentSong];
    songView.showInfoButton = NO;
    //songView.showArtwork = NO;
    [self.view addSubview:songView];
}

- (void)updateSong:(MPMediaItem*)song
{
    currentSong = song;
    [songView updateSongInfo:currentSong];
    [self updateArtwork];
}

- (void)updateArtwork
{
    MPMediaItemArtwork *albumItem = [currentSong valueForProperty:MPMediaItemPropertyArtwork];
    if (albumItem)
        albumArtwork.image = [albumItem imageWithSize:CGSizeMake(albumItem.bounds.size.width, albumItem.bounds.size.height)];
    else
        NSLog(@"No Current Image\n");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
