//
//  SoundCloudTabViewController.m
//  Songtrain
//
//  Created by Quinton Petty on 10/18/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "SoundCloudTabViewController.h"
#import "CocoaSoundCloudUI/Sources/SoundCloudUI/SCUI.h"
#import "SoundCloudSong.h"
#import "SoundCloudSongViewController.h"

@interface SoundCloudTabViewController ()

@end

@implementation SoundCloudTabViewController {
    NSArray *tracks, *playlists;
    SCLoginViewController *login;
    UISegmentedControl *segmented;
    
    UITableView *playlistTable;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        self.wholeTableView = [[STMusicPickerTableView alloc] init];
        self.wholeTableView.dataSource = self;
        self.wholeTableView.delegate = self;
        
        //[SCSoundCloud removeAccess];
        [self setupSoundCloud];
        
        if ([SCSoundCloud account] == nil) {
            [self getAuthViewController];
        } else {
            [self getFavorites];
            [self getPlaylists];
        }
        
        segmented = [[UISegmentedControl alloc] initWithItems:@[@"Likes", @"Playlists"]];
        segmented.backgroundColor = [UIColor darkGrayColor];
        segmented.selectedSegmentIndex = 0;
        segmented.tintColor = UIColorFromRGBWithAlpha(0x7FA8D7, 1.0);
        [segmented addTarget:self action:@selector(segementedControlChanged:) forControlEvents: UIControlEventValueChanged];
        //[self.view addSubview:segmented];
        
        playlistTable = [[STMusicPickerTableView alloc] init];
        playlistTable.delegate = self;
        playlistTable.dataSource = self;
        playlistTable.hidden = YES;
        //[self.view addSubview:playlistTable];
    }
    return self;
}

- (void)setupSoundCloud {
    NSLog(@"Setting up SoundCloud");
    [SCSoundCloud setClientID:@"76afdeecb23413b7ace7f1cf4ef90e9d" secret:@"f561aa48f95d4d2290db923adbb36f04" redirectURL:[NSURL URLWithString:@"songtrain://oauth"]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.wholeTableView];
    [self.view addSubview:segmented];
    [self.view addSubview:playlistTable];
    NSLog(@"self delegate: %@", self.delegate);
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.wholeTableView reloadData];
    [self getFavorites];
    [self getPlaylists];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.wholeTableView.frame = CGRectMake(self.view.frame.origin.x,
                                           self.view.frame.origin.y,
                                           self.view.frame.size.width,
                                           self.view.frame.size.height);

    segmented.frame = CGRectMake(self.view.frame.origin.x,
                                 self.view.frame.origin.y + 64.0,
                                 self.view.frame.size.width,
                                 28.0);
    
    self.wholeTableView.frame = CGRectMake(self.wholeTableView.frame.origin.x,
                                           self.wholeTableView.frame.origin.y + segmented.frame.size.height,
                                           self.wholeTableView.frame.size.width,
                                           self.wholeTableView.frame.size.height);
    
    playlistTable.frame = CGRectMake(self.wholeTableView.frame.origin.x,
                                     self.wholeTableView.frame.origin.y + segmented.frame.origin.y,
                                     self.wholeTableView.frame.size.width,
                                     self.wholeTableView.frame.size.height);
    
    login.view.frame = CGRectMake(self.view.frame.origin.x,
                                  self.view.frame.origin.y + 32.0,
                                  self.view.frame.size.width,
                                  self.view.frame.size.height);
}

/*
-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    playlistTable.frame = self.wholeTableView.frame;
}
*/
- (void)getFavorites {
    NSLog(@"Soundcloud account: %@", [SCSoundCloud account]);
    if ([SCSoundCloud account] != nil) {
        SCRequestResponseHandler handler;
        handler = ^(NSURLResponse *response, NSData *data, NSError *error) {
            NSError *jsonError = nil;
            NSJSONSerialization *jsonResponse = [NSJSONSerialization
                                                 JSONObjectWithData:data
                                                 options:0
                                                 error:&jsonError];
            if (!jsonError && [jsonResponse isKindOfClass:[NSArray class]]) {
                //NSLog(@"Json response: %@", (NSArray *)jsonResponse);
                tracks = (NSArray *)jsonResponse;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.wholeTableView reloadData];
                    NSLog(@"Updated favorites");
                });
            }
        };
        
        NSString *resourceURL = @"https://api.soundcloud.com/me/favorites.json";
        [SCRequest performMethod:SCRequestMethodGET onResource:[NSURL URLWithString:resourceURL] usingParameters:nil withAccount:[SCSoundCloud account] sendingProgressHandler:nil responseHandler:handler];
    } else {
        tracks = nil;
    }
}

- (void)getPlaylists {
    NSLog(@"Soundcloud account: %@", [SCSoundCloud account]);
    if ([SCSoundCloud account] != nil) {
        SCRequestResponseHandler handler;
        handler = ^(NSURLResponse *response, NSData *data, NSError *error) {
            NSError *jsonError = nil;
            NSJSONSerialization *jsonResponse = [NSJSONSerialization
                                                 JSONObjectWithData:data
                                                 options:0
                                                 error:&jsonError];
            if (!jsonError && [jsonResponse isKindOfClass:[NSArray class]]) {
                //NSLog(@"Json response: %@", (NSArray *)jsonResponse);
                playlists = (NSArray *)jsonResponse;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [playlistTable reloadData];
                    NSLog(@"Updated playlists");
                });
            }
        };
        
        NSString *resourceURL = @"https://api.soundcloud.com/me/playlists.json";
        [SCRequest performMethod:SCRequestMethodGET onResource:[NSURL URLWithString:resourceURL] usingParameters:nil withAccount:[SCSoundCloud account] sendingProgressHandler:nil responseHandler:handler];
    } else {
        playlists = nil;
    }
}

-(void)getAuthViewController {
    SCLoginViewControllerCompletionHandler handler = ^(NSError *error) {
        if (SC_CANCELED(error)) {
            NSLog(@"Canceled!");
        } else if (error) {
            NSLog(@"Error: %@", [error localizedDescription]);
        } else {
            NSLog(@"Done!");
            [login removeFromParentViewController];
            [login.view removeFromSuperview];
            [self getFavorites];
            [self getPlaylists];
        }
    };
    
    [SCSoundCloud requestAccessWithPreparedAuthorizationURLHandler:^(NSURL *preparedURL) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            login = [SCLoginViewController loginViewControllerWithPreparedURL:preparedURL completionHandler:handler];
            [self addChildViewController:login];
            [self.view addSubview:login.view];
        });
    }];
}

-(IBAction)segementedControlChanged:(id)sender {
    if ([segmented selectedSegmentIndex] == 0) {
        self.wholeTableView.hidden = NO;
        playlistTable.hidden = YES;
    } else {
        self.wholeTableView.hidden = YES;
        playlistTable.hidden = NO;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView == playlistTable) {
        return playlists.count;
    }
    
    return tracks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    STSongTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MusicCell"];
    
    if (!cell) {
        cell = [[STSongTableViewCell alloc] init];
        [cell setRestorationIdentifier:@"MusicCell"];
    }
    
    cell.backgroundColor = UIColorFromRGBWithAlpha(0x4E5257, 0.3);
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.userInteractionEnabled = YES;
    
    if (tableView == playlistTable) {
        cell.textLabel.text = [playlists objectAtIndex:indexPath.row][@"title"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.textLabel.text = [tracks objectAtIndex:indexPath.row][@"title"];
        SoundCloudSong *newSong = [[SoundCloudSong alloc] initWithURL:[NSURL URLWithString:[tracks objectAtIndex:indexPath.row][@"uri"]] andPeer:[[QPSessionManager sessionManager] pid]];
        if ([self.delegate isItemSelected:newSong]) {
            cell.textLabel.textColor = UIColorFromRGBWithAlpha(0x7FA8D7, 1.0);
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == playlistTable) {
        SoundCloudSongViewController *songsView = [[SoundCloudSongViewController alloc] initWithTracks:[playlists objectAtIndex:indexPath.row][@"tracks"]];
        songsView.title = [playlists objectAtIndex:indexPath.row][@"title"];
        songsView.delegate = self.delegate;
        [self.navigationController pushViewController:songsView animated:YES];
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    SoundCloudSong *newSong = [[SoundCloudSong alloc] initWithSoundCloudDictionary:[tracks objectAtIndex:indexPath.row] andPeer:[[QPSessionManager sessionManager] pid]];
    if ([self.delegate isItemSelected:newSong]) {
        [self.delegate removeItem:newSong];
    }
    else {
        [self.delegate addItem:newSong];
    }
    [self.wholeTableView reloadData];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
