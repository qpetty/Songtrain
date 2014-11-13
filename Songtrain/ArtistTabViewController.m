//
//  ArtistTabViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 4/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "ArtistTabViewController.h"

@interface ArtistTabViewController ()

@end

@implementation ArtistTabViewController

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
        
        self.wholeTableView = [[STMusicPickerTableView alloc] init];
        self.wholeTableView.dataSource = self;
        self.wholeTableView.delegate = self;
        [self.view addSubview:self.wholeTableView];
        
        query = [MPMediaQuery playlistsQuery];
        
        [query setGroupingType:MPMediaGroupingArtist];
        [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInt:MPMediaTypeMusic] forProperty:MPMediaItemPropertyMediaType]];
        displayItems = [query collections];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    self.wholeTableView.frame = CGRectMake(self.view.bounds.origin.x,
                                           self.view.bounds.origin.y,
                                           self.view.bounds.size.width,
                                           self.view.bounds.size.height);
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
    return [[query collectionSections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[[query collectionSections] objectAtIndex:section] range].length;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    NSMutableArray *titles = [[NSMutableArray alloc] init];
    
    //[titles addObject:UITableViewIndexSearch];

    for (MPMediaQuerySection *section in query.itemSections) {
        [titles addObject:section.title];
    }
    return titles;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[[query collectionSections] objectAtIndex:section] title];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    STSongTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MusicCell"];
    
    if (!cell) {
        cell = [[STSongTableViewCell alloc] init];
        [cell setRestorationIdentifier:@"MusicCell"];
    }
    
    
    NSUInteger ndx = [[[query collectionSections] objectAtIndex:indexPath.section] range].location + indexPath.row;
    
    cell.textLabel.text = [[[displayItems objectAtIndex:ndx] representativeItem] valueForProperty:MPMediaItemPropertyArtist];
    
    //Query to see if songs are pickable
    MPMediaQuery *songQuery = [MPMediaQuery songsQuery];
    [songQuery addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:cell.textLabel.text forProperty:MPMediaItemPropertyArtist]];
    
    BOOL displayName = NO;

    for (MPMediaItem *item in songQuery.items) {
        if ([item valueForProperty:MPMediaItemPropertyAssetURL]) {
            displayName = YES;
        }
    }
    
    if (displayName) {
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.userInteractionEnabled = YES;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else {
        cell.textLabel.textColor = [UIColor grayColor];
        cell.userInteractionEnabled = NO;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MPMediaQuery *artistQuery = [[MPMediaQuery alloc] init];
    NSUInteger ndx = [[[query collectionSections] objectAtIndex:indexPath.section] range].location + indexPath.row;
    NSString *artistName = [[[displayItems objectAtIndex:ndx] representativeItem] valueForProperty:MPMediaItemPropertyArtist];
    
    [artistQuery addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:artistName forProperty:MPMediaItemPropertyArtist]];
    [artistQuery setGroupingType:MPMediaGroupingTitle];
    
    SongTabViewController *songsView = [[SongTabViewController alloc] initWithQuery:artistQuery];
    songsView.title = artistName;
    songsView.delegate = self.delegate;
    [self.navigationController pushViewController:songsView animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    HeaderSongCellView *cell = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"HeaderSong"];
    cell.title.text = [[query.itemSections objectAtIndex:section] title];
    return cell;
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
