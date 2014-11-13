//
//  MusicPickerViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 4/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "MusicPickerViewController.h"
#import "Song.h"

#define FINISHED_WITH_ADDING_SONGS @"Add"

@interface MusicPickerViewController (){
    NSMutableArray *allMediaItems, *doneButtons;
    UIBarButtonItem *doneButton1, *doneButton2, *doneButton3;
    
    MusicNavigationViewController *soundCloudFrame;
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
    
    //Playlists Tab
    
    PlaylistTabViewController *playListViewController = [[PlaylistTabViewController alloc] init];
    playListViewController.title = @"Playlists";
    playListViewController.delegate = self;
    
    MusicNavigationViewController *playlists = [[MusicNavigationViewController alloc] initWithRootViewController:playListViewController];
    playlists.tabBarItem = [[UITabBarItem alloc] initWithTitle:playListViewController.title image:[UIImage imageNamed:@"playlist_inactive"] selectedImage:[UIImage imageNamed:@"playlist_active"]];
    
    //Artists Tab
    
    ArtistTabViewController *artistViewController = [[ArtistTabViewController alloc] init];
    artistViewController.title = @"Artists";
    artistViewController.delegate = self;
    
    MusicNavigationViewController *artists = [[MusicNavigationViewController alloc] initWithRootViewController:artistViewController];
    artists.tabBarItem = [[UITabBarItem alloc] initWithTitle:artistViewController.title image:[UIImage imageNamed:@"artist_inactive"] selectedImage:[UIImage imageNamed:@"artist_active"]];
    
    //Songs Tab
    
    SongTabViewController *songViewController = [[SongTabViewController alloc] initWithQuery:[MPMediaQuery songsQuery]];
    songViewController.title = @"Songs";
    songViewController.delegate = self;
    
    MusicNavigationViewController *songs = [[MusicNavigationViewController alloc] initWithRootViewController:songViewController];
    songs.tabBarItem = [[UITabBarItem alloc] initWithTitle:songViewController.title image:[UIImage imageNamed:@"song_inactive"] selectedImage:[UIImage imageNamed:@"song_active"]];
    
    //Soundcloud
    
    SoundCloudTabViewController *soundCloudViewController = [[SoundCloudTabViewController alloc] init];
    soundCloudViewController.title = @"SoundCloud";
    soundCloudViewController.delegate = self;
    
    MusicNavigationViewController *soundCloud = [[MusicNavigationViewController alloc] initWithRootViewController:soundCloudViewController];
    soundCloud.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"SoundCloud" image:[UIImage imageNamed:@"soundcloud_icon"] selectedImage:[UIImage imageNamed:@"soundcloud_icon"]];
    
    //Putting everything in the tab bar controller
    
    NSArray *controllers = [NSArray arrayWithObjects:playlists, artists, songs, soundCloud, nil];
    
    self.viewControllers = controllers;
    
    self.tabBar.tintColor = UIColorFromRGBWithAlpha(0x7FA8D7, 1.0);
    self.tabBar.barTintColor = [UIColor darkGrayColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [allMediaItems removeAllObjects];
}

- (void)addItem:(id)item
{
    [allMediaItems addObject:item];
    for (UIBarButtonItem *button in doneButtons) {
        button.title = FINISHED_WITH_ADDING_SONGS;
    }
}

- (void)removeItem:(id)item
{
    [allMediaItems removeObject:item];
    if (![allMediaItems count]) {
        for (UIBarButtonItem *button in doneButtons) {
            button.title = @"Cancel";
        }
    }
}

- (BOOL)isItemSelected:(id)item
{
    return [allMediaItems containsObject:item];
}

- (void)addButton:(UIBarButtonItem*)button {
    if (allMediaItems.count) {
        button.title = FINISHED_WITH_ADDING_SONGS;
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
        NSMutableArray *urlItems = [[NSMutableArray alloc] init];
        NSMutableArray *mediaItems = [[NSMutableArray alloc] init];
        
        for (id oneItem in allMediaItems) {
            if ([oneItem isKindOfClass:[Song class]]) {
                [urlItems addObject:oneItem];
            } else {
                [mediaItems addObject:oneItem];
            }
        }
        
        _selectedMediaItems = [NSArray arrayWithArray:mediaItems];
        MPMediaItemCollection *itemCollection = nil;
        if (mediaItems.count) {
            itemCollection = [MPMediaItemCollection collectionWithItems:_selectedMediaItems];
        }
        [self.delegate musicPicker:self didPickItems:urlItems andMediaItems:itemCollection];

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
