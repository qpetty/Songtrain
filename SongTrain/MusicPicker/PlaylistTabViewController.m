//
//  PlaylistTabViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 4/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "PlaylistTabViewController.h"

@interface PlaylistTabViewController ()

@end

@implementation PlaylistTabViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)init
{
    self = [super init];
    if (self) {
        query = [MPMediaQuery playlistsQuery];
        
        [query setGroupingType:MPMediaGroupingPlaylist];
        [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInt:MPMediaTypeMusic] forProperty:MPMediaItemPropertyMediaType]];
        displayItems = [query collections];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
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
    return [displayItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    NSUInteger ndx = [[[query itemSections] objectAtIndex:indexPath.section] range].location + indexPath.row;
    
    cell.textLabel.text = [[displayItems objectAtIndex:ndx] valueForProperty:MPMediaPlaylistPropertyName];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.userInteractionEnabled = YES;
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MPMediaQuery *artistQuery = [[MPMediaQuery alloc] init];
    NSUInteger ndx = [[[query itemSections] objectAtIndex:indexPath.section] range].location + indexPath.row;
    NSString *playlistName = [[displayItems objectAtIndex:ndx] valueForProperty:MPMediaPlaylistPropertyName];
    
    [artistQuery addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:playlistName forProperty:MPMediaPlaylistPropertyName]];
    //[artistQuery setGroupingType:MPMediaGroupingAlbum];
    
    SongTabViewController *songsView = [[SongTabViewController alloc] initWithQuery:artistQuery];
    songsView.title = playlistName;
    [self.navigationController pushViewController:songsView animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
