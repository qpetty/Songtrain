//
//  SoundCloudSongViewController.m
//  Songtrain
//
//  Created by Quinton Petty on 11/1/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "SoundCloudSongViewController.h"
#import "SoundCloudSong.h"

@interface SoundCloudSongViewController ()

@end

@implementation SoundCloudSongViewController {
    NSArray *tracks;
}

-(instancetype)initWithTracks:(NSArray*)arrayOfTracks {
    self = [super init];
    if (self) {
        self.wholeTableView = [[STMusicPickerTableView alloc] init];
        self.wholeTableView.dataSource = self;
        self.wholeTableView.delegate = self;
        
        tracks = arrayOfTracks;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.wholeTableView];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.wholeTableView reloadData];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.wholeTableView.frame = CGRectMake(self.view.frame.origin.x,
                                           self.view.frame.origin.y,
                                           self.view.frame.size.width,
                                           self.view.frame.size.height);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    cell.textLabel.text = [tracks objectAtIndex:indexPath.row][@"title"];
    SoundCloudSong *newSong = [[SoundCloudSong alloc] initWithURL:[NSURL URLWithString:[tracks objectAtIndex:indexPath.row][@"uri"]] andPeer:[[QPSessionManager sessionManager] pid]];
    if ([self.delegate isItemSelected:newSong]) {
        cell.textLabel.textColor = UIColorFromRGBWithAlpha(0x7FA8D7, 1.0);
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
