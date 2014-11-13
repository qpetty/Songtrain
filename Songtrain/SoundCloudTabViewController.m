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
    
    SoundCloudSongViewController *songView;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        segmented = [[UISegmentedControl alloc] initWithItems:@[@"Likes", @"Playlists"]];
        segmented.backgroundColor = [UIColor darkGrayColor];
        segmented.selectedSegmentIndex = 0;
        segmented.tintColor = UIColorFromRGBWithAlpha(0x7FA8D7, 1.0);
        [segmented addTarget:self action:@selector(segementedControlChanged:) forControlEvents: UIControlEventValueChanged];
        [self.view addSubview:segmented];
        
        self.wholeTableView = [[STMusicPickerTableView alloc] init];
        self.wholeTableView.dataSource = self;
        self.wholeTableView.delegate = self;
        self.wholeTableView.hidden = YES;
        [self.view addSubview:self.wholeTableView];
        
        //songView = [[SoundCloudSongViewController alloc] initWithTracks:nil andURL:@"https://api.soundcloud.com/me/favorites.json?offset=0&limit=11"];
        songView = [[SoundCloudSongViewController alloc] initWithTracks:nil andURL:@"https://api.soundcloud.com/me/favorites.json"];
        [self addChildViewController:songView];
        [self.view addSubview:songView.view];
        
        //[SCSoundCloud removeAccess];
        [self setupSoundCloud];
        
        if ([SCSoundCloud account] == nil) {
            [self getAuthViewController];
        } else {
            [self getPlaylists];
        }
    }
    return self;
}

- (void)setupSoundCloud {
    NSLog(@"Setting up SoundCloud");
    [SCSoundCloud setClientID:@"76afdeecb23413b7ace7f1cf4ef90e9d" secret:@"f561aa48f95d4d2290db923adbb36f04" redirectURL:[NSURL URLWithString:@"songtrain://oauth"]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    songView.delegate = self.delegate;
    [self.wholeTableView reloadData];
    [self getPlaylists];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    float topHeight = 64.0;

    login.view.frame = CGRectMake(self.view.frame.origin.x,
                                  self.view.frame.origin.y + 32.0,
                                  self.view.frame.size.width,
                                  self.view.frame.size.height - topHeight - 49.0);
    
    segmented.frame = CGRectMake(self.view.frame.origin.x,
                                 self.view.frame.origin.y + topHeight,
                                 self.view.frame.size.width,
                                 28.0);
    topHeight += segmented.frame.size.height;
    
    self.wholeTableView.frame = CGRectMake(self.view.frame.origin.x,
                                           topHeight,
                                           self.view.frame.size.width,
                                           self.view.frame.size.height - topHeight - 49.0);
    
    songView.view.frame = CGRectMake(self.view.frame.origin.x,
                                     topHeight,
                                     self.view.frame.size.width,
                                     self.view.frame.size.height - topHeight - 49.0);
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
                    [self.wholeTableView reloadData];
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
        self.wholeTableView.hidden = YES;
        songView.view.hidden = NO;
    } else {
        self.wholeTableView.hidden = NO;
        songView.view.hidden = YES;
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
    
    return playlists.count;
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
    
    cell.textLabel.text = [playlists objectAtIndex:indexPath.row][@"title"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SoundCloudSongViewController *songsView = [[SoundCloudSongViewController alloc] initWithTracks:[playlists objectAtIndex:indexPath.row][@"tracks"] andURL:nil];
    songsView.title = [playlists objectAtIndex:indexPath.row][@"title"];
    songsView.delegate = self.delegate;
    [self.navigationController pushViewController:songsView animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
