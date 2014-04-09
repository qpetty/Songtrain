//
//  MusicPickerViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 4/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "MusicPickerViewController.h"

@interface MusicPickerViewController ()

@end

@implementation MusicPickerViewController

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
    
    PlaylistTabViewController *playlists = [[PlaylistTabViewController alloc] init];
    playlists.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Playlists" image:nil selectedImage:nil];
    
    ArtistTabViewController *artists = [[ArtistTabViewController alloc] init];
    artists.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Artists" image:nil selectedImage:nil];
    
    SongTabViewController *songs = [[SongTabViewController alloc] initWithQuery:[MPMediaQuery songsQuery]];
    songs.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Songs" image:nil selectedImage:nil];
    
    NSArray *controllers = [NSArray arrayWithObjects:playlists, artists, songs, nil];
    
    self.viewControllers = controllers;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
