//
//  SoundCloudSongViewController.m
//  Songtrain
//
//  Created by Quinton Petty on 11/1/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "SoundCloudSongViewController.h"
#import "CocoaSoundCloudUI/Sources/SoundCloudUI/SCUI.h"
#import "SVPullToRefresh.h"
#import "SoundCloudSong.h"

@interface SoundCloudSongViewController ()

@end

@implementation SoundCloudSongViewController

-(instancetype)initWithTracks:(NSArray*)arrayOfTracks andURL:(NSString*)url {
    self = [super init];
    if (self) {
        self.wholeTableView = [[STMusicPickerTableView alloc] init];
        self.wholeTableView.dataSource = self;
        self.wholeTableView.delegate = self;
        //self.wholeTableView.pullToRefreshView.activityIndicatorViewColor = [UIColor whiteColor];
        self.wholeTableView.pullToRefreshView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        [self.view addSubview:self.wholeTableView];
        
        _location = url;
        _tracks = arrayOfTracks;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak SoundCloudSongViewController *weakSelf = self;
    
    // setup pull-to-refresh
    [self.wholeTableView addPullToRefreshWithActionHandler:^{
        [weakSelf getFavorites];
    }];
    
    // setup infinite scrolling
    
    [self.wholeTableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf extendFavorites];
    }];
    
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self update];
    NSLog(@"view will appear");
}

-(void)update {
    if (self.tracks == nil) {
        [self.wholeTableView triggerPullToRefresh];
    } else {
        [self.wholeTableView reloadData];
    }
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.wholeTableView.frame = CGRectMake(self.view.bounds.origin.x,
                                           self.view.bounds.origin.y,
                                           self.view.bounds.size.width,
                                           self.view.bounds.size.height);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getFavorites {
    __weak SoundCloudSongViewController *weakSelf = self;
    
    if ([SCSoundCloud account] != nil) {
        SCRequestResponseHandler handler;
        handler = ^(NSURLResponse *response, NSData *data, NSError *error) {
            NSError *jsonError = nil;
            
            if (response == nil) {
                return;
            }
            
            NSJSONSerialization *jsonResponse = [NSJSONSerialization
                                                 JSONObjectWithData:data
                                                 options:0
                                                 error:&jsonError];
            if (!jsonError && [jsonResponse isKindOfClass:[NSArray class]] && ((NSArray *)jsonResponse).count > 0) {
                //NSLog(@"Json response: %@", (NSArray *)jsonResponse);
                //[self.tracks removeAllObjects];
                _tracks = (NSArray *)jsonResponse;
                NSUInteger numReturned = _tracks.count;
                NSLog(@"Updated favorites to %lu", (unsigned long)((NSArray *)jsonResponse).count);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.wholeTableView reloadData];
                    [weakSelf.wholeTableView.pullToRefreshView stopAnimating];
                    if (numReturned < kSoundCloudSongInitalLoad) {
                        weakSelf.wholeTableView.showsInfiniteScrolling = NO;
                    }
                });
            }
            else {
                [weakSelf.wholeTableView.infiniteScrollingView stopAnimating];
                weakSelf.wholeTableView.showsInfiniteScrolling = NO;
            }
        };
        
        self.wholeTableView.showsInfiniteScrolling = YES;
        NSString *requestURL = [NSString stringWithFormat:@"%@?offset=0&limit=%d", self.location, kSoundCloudSongInitalLoad];
        
        [SCRequest performMethod:SCRequestMethodGET onResource:[NSURL URLWithString:requestURL] usingParameters:nil withAccount:[SCSoundCloud account] sendingProgressHandler:nil responseHandler:handler];
    } else {
        self.tracks = nil;
    }
}

- (void)extendFavorites {
    __weak SoundCloudSongViewController *weakSelf = self;
    
    if ([SCSoundCloud account] != nil) {
        SCRequestResponseHandler handler;
        handler = ^(NSURLResponse *response, NSData *data, NSError *error) {
            NSError *jsonError = nil;
            if (response == nil) {
                return;
            }
            
            NSJSONSerialization *jsonResponse = [NSJSONSerialization
                                                 JSONObjectWithData:data
                                                 options:0
                                                 error:&jsonError];
            if (!jsonError && [jsonResponse isKindOfClass:[NSArray class]] && ((NSArray *)jsonResponse).count > 0) {
                //NSLog(@"Json response: %@", (NSArray *)jsonResponse);
                //_tracks = (NSArray *)jsonResponse;
                NSUInteger numReturned = ((NSArray *)jsonResponse).count;
                
                _tracks = [_tracks arrayByAddingObjectsFromArray:(NSArray *)jsonResponse];
                NSLog(@"Added %lu to end of favorites", (unsigned long)numReturned);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.wholeTableView reloadData];
                    [weakSelf.wholeTableView.infiniteScrollingView stopAnimating];
                    if (numReturned < kSoundCloudSongNextLoad) {
                        weakSelf.wholeTableView.showsInfiniteScrolling = NO;
                    }
                });
            } else {
                [weakSelf.wholeTableView.infiniteScrollingView stopAnimating];
                weakSelf.wholeTableView.showsInfiniteScrolling = NO;
            }
        };
        
        NSString *requestURL = [NSString stringWithFormat:@"%@?offset=%lu&limit=%d", self.location, (unsigned long)self.tracks.count, kSoundCloudSongNextLoad];
        
        [SCRequest performMethod:SCRequestMethodGET onResource:[NSURL URLWithString:requestURL] usingParameters:nil withAccount:[SCSoundCloud account] sendingProgressHandler:nil responseHandler:handler];
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
    
    return self.tracks.count;
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
    
    cell.textLabel.text = [self.tracks objectAtIndex:indexPath.row][@"title"];
    SoundCloudSong *newSong = [[SoundCloudSong alloc] initWithURL:[NSURL URLWithString:[self.tracks objectAtIndex:indexPath.row][@"uri"]] andPeer:[[QPSessionManager sessionManager] pid]];
    if ([self.delegate isItemSelected:newSong]) {
        cell.textLabel.textColor = UIColorFromRGBWithAlpha(0x7FA8D7, 1.0);
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SoundCloudSong *newSong = [[SoundCloudSong alloc] initWithSoundCloudDictionary:[self.tracks objectAtIndex:indexPath.row] andPeer:[[QPSessionManager sessionManager] pid]];
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
