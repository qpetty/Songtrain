//
//  MusicPickerViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 4/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "MusicPickerViewController.h"

@interface MusicPickerViewController (){
    NSMutableArray *allMediaItems, *doneButtons;
    UIBarButtonItem *doneButton1, *doneButton2, *doneButton3;
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
    
    allMediaItems = [[NSMutableArray alloc] init];
    
    doneButtons = [[NSMutableArray alloc] init];
    
    PlaylistTabViewController *playListViewController = [[PlaylistTabViewController alloc] init];
    playListViewController.title = @"Playlists";
    playListViewController.delegate = self;
    
    MusicNavigationViewController *playlists = [[MusicNavigationViewController alloc] initWithRootViewController:playListViewController];
    playlists.tabBarItem = [[UITabBarItem alloc] initWithTitle:playListViewController.title image:nil selectedImage:nil];
    [playlists.tabBarItem setImage: [UIImage imageNamed:@"playlist_inactive"]];
    [playlists.tabBarItem setSelectedImage:[UIImage imageNamed:@"playlist_active"]];
    
    ArtistTabViewController *artistViewController = [[ArtistTabViewController alloc] init];
    artistViewController.title = @"Artists";
    artistViewController.delegate = self;
    
    MusicNavigationViewController *artists = [[MusicNavigationViewController alloc] initWithRootViewController:artistViewController];
    artists.tabBarItem = [[UITabBarItem alloc] initWithTitle:artistViewController.title image:nil selectedImage:nil];

    [artists.tabBarItem setImage: [UIImage imageNamed:@"artist_inactive"]];
    [artists.tabBarItem setSelectedImage:[UIImage imageNamed:@"artist_active"]];
    
    SongTabViewController *songViewController = [[SongTabViewController alloc] initWithQuery:[MPMediaQuery songsQuery]];
    songViewController.title = @"Songs";
    songViewController.delegate = self;
    
    MusicNavigationViewController *songs = [[MusicNavigationViewController alloc] initWithRootViewController:songViewController];
    songs.tabBarItem = [[UITabBarItem alloc] initWithTitle:songViewController.title image:nil selectedImage:nil];
    [songs.tabBarItem setImage: [UIImage imageNamed:@"song_inactive"]];
    [songs.tabBarItem setSelectedImage:[UIImage imageNamed:@"song_active"]];
    
    NSArray *controllers = [NSArray arrayWithObjects:playlists, artists, songs, nil];
    
    self.viewControllers = controllers;
    
    
    self.tabBar.tintColor = UIColorFromRGB(0x7FA8D7);
    self.tabBar.barTintColor = [UIColor darkGrayColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addItem:(MPMediaItem*)item
{
    [allMediaItems addObject:item];
    
    for (UIBarButtonItem *button in doneButtons) {
        button.title = @"Done";
    }
}

- (void)removeItem:(MPMediaItem*)item
{
    [allMediaItems removeObject:item];
    if (![allMediaItems count]) {
        for (UIBarButtonItem *button in doneButtons) {
            button.title = @"Cancel";
        }
    }
}

- (BOOL)isItemSelected:(MPMediaItem*)item
{
    return [allMediaItems containsObject:item];
}

- (void)addButton:(UIBarButtonItem*)button {
    if (allMediaItems.count) {
        button.title = @"Done";
    }
    else {
        button.title = @"Cancel";
    }
    [doneButtons addObject:button];
}

- (void)removeButton:(UIBarButtonItem*)button {
    [doneButtons removeObject:button];
}

- (void)done
{
    if ([allMediaItems count]) {
        [self.delegate mediaPicker:(MPMediaPickerController*)self didPickMediaItems:[MPMediaItemCollection collectionWithItems:allMediaItems]];
        [allMediaItems removeAllObjects];
        for (UIBarButtonItem *button in doneButtons) {
            button.title = @"Cancel";
        }
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
