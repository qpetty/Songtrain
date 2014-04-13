//
//  MusicPickerViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 4/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "MusicPickerViewController.h"

@interface MusicPickerViewController (){
    NSMutableArray *allMediaItems;
}

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
    
    self.view.backgroundColor = [UIColor whiteColor];
    allMediaItems = [[NSMutableArray alloc] init];
    
    PlaylistTabViewController *playListViewController = [[PlaylistTabViewController alloc] init];
    playListViewController.title = @"Playlists";
    playListViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done)];
    UINavigationController *playlists = [[UINavigationController alloc] initWithRootViewController:playListViewController];
    playlists.tabBarItem = [[UITabBarItem alloc] initWithTitle:playListViewController.title image:nil selectedImage:nil];
    
    ArtistTabViewController *artistViewController = [[ArtistTabViewController alloc] init];
    artistViewController.title = @"Artists";
    artistViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done)];
    UINavigationController *artists = [[UINavigationController alloc] initWithRootViewController:artistViewController];
    artists.tabBarItem = [[UITabBarItem alloc] initWithTitle:artistViewController.title image:nil selectedImage:nil];
    
    SongTabViewController *songViewController = [[SongTabViewController alloc] initWithQuery:[MPMediaQuery songsQuery]];
    songViewController.title = @"Songs";
    songViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done)];
    UINavigationController *songs = [[UINavigationController alloc] initWithRootViewController:songViewController];
    songs.tabBarItem = [[UITabBarItem alloc] initWithTitle:songViewController.title image:nil selectedImage:nil];
    
    NSArray *controllers = [NSArray arrayWithObjects:playlists, artists, songs, nil];
    
    self.viewControllers = controllers;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addItem:(MPMediaItem*)item
{
    [allMediaItems addObject:item];
}

- (void)removeItem:(MPMediaItem*)item
{
    [allMediaItems removeObject:item];
}

- (BOOL)isItemSelected:(MPMediaItem*)item
{
    return [allMediaItems containsObject:item];
}

- (void)done
{
    if ([allMediaItems count]) {
        [self.delegate mediaPicker:(MPMediaPickerController*)self didPickMediaItems:[MPMediaItemCollection collectionWithItems:allMediaItems]];
    }
    else {
        [self.delegate mediaPickerDidCancel:(MPMediaPickerController*)self];
    }
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
