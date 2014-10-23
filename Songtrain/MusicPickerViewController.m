//
//  MusicPickerViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 4/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "MusicPickerViewController.h"
#import "Song.h"

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
    [SCSoundCloud removeAccess];
    
    [self setupSoundCloud];
    
    UIViewController *soundCloudRoot;
    
    if ([SCSoundCloud account] == nil) {
        [self getAuthViewController];
        soundCloudRoot = [[UIViewController alloc] init];
    } else {
        //Show tracks otherwise
        soundCloudRoot = [self soundCloudBaseViewController];
    }
    
    soundCloudFrame = [[MusicNavigationViewController alloc] initWithRootViewController:soundCloudRoot];
    soundCloudFrame.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"SoundCloud" image:[UIImage imageNamed:@"soundcloud_icon"] selectedImage:[UIImage imageNamed:@"soundcloud_icon"]];
    
    //Putting everything in the tab bar controller
    
    NSArray *controllers = [NSArray arrayWithObjects:playlists, artists, songs, soundCloudFrame, nil];
    
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
        button.title = @"Done";
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

- (void)setupSoundCloud {
    NSLog(@"Setting up SoundCloud");
    [SCSoundCloud setClientID:@"76afdeecb23413b7ace7f1cf4ef90e9d" secret:@"f561aa48f95d4d2290db923adbb36f04" redirectURL:[NSURL URLWithString:@"songtrain://oauth"]];
}

-(void)getAuthViewController {
    SCLoginViewControllerCompletionHandler handler = ^(NSError *error) {
        if (SC_CANCELED(error)) {
            NSLog(@"Canceled!");
        } else if (error) {
            NSLog(@"Error: %@", [error localizedDescription]);
        } else {
            NSLog(@"Done!");
            soundCloudFrame.navigationBarHidden = NO;
            soundCloudFrame.viewControllers = [NSArray arrayWithObject:[self soundCloudBaseViewController]];
        }
    };
    
    [SCSoundCloud requestAccessWithPreparedAuthorizationURLHandler:^(NSURL *preparedURL) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            SCLoginViewController *login = [SCLoginViewController loginViewControllerWithPreparedURL:preparedURL completionHandler:handler];
            login.delegate = self;
            soundCloudFrame.navigationBarHidden = YES;
            soundCloudFrame.viewControllers = [NSArray arrayWithObject:login];
        });
    }];
}

-(UIViewController*)soundCloudBaseViewController {
    SoundCloudTabViewController *viewcontroller = [[SoundCloudTabViewController alloc] init];
    viewcontroller.delegate = self;
    
    return viewcontroller;
}

- (void)dismissSCLoginView {
    NSLog(@"Here");
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
