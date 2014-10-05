//
//  TabViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 4/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "TabViewController.h"
#import "HeaderSongCellView.h"

@interface TabViewController () {
    UITableView *wholeTableView;
}

@end

@implementation TabViewController

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
        wholeTableView = [[UITableView alloc] init];
        wholeTableView.dataSource = self;
        wholeTableView.delegate = self;
        
        wholeTableView.backgroundColor = UIColorFromRGBWithAlpha(0x222222, 1.0);
        wholeTableView.sectionIndexBackgroundColor = [UIColor clearColor];
        wholeTableView.sectionIndexColor = UIColorFromRGBWithAlpha(0xFFFFFF, 1.0);
        
        wholeTableView.separatorColor = UIColorFromRGBWithAlpha(0x222222, 1.0);
        
        wholeTableView.layer.borderWidth = 0.5f;
        wholeTableView.layer.borderColor = UIColorFromRGBWithAlpha(0x252525, 0.7).CGColor;
        
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self.delegate action:@selector(done)];
        self.navigationItem.rightBarButtonItem = item;
        
        [wholeTableView registerNib:[UINib nibWithNibName:@"HeaderSongCellView" bundle:[NSBundle mainBundle]] forHeaderFooterViewReuseIdentifier:@"HeaderSong"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:wholeTableView];
    [self.delegate addButton:self.navigationItem.rightBarButtonItem];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [wholeTableView reloadData];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    wholeTableView.frame = CGRectMake(self.view.frame.origin.x,
                                      self.view.frame.origin.y,
                                      self.view.frame.size.width,
                                      self.view.frame.size.height - 49);
    
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
    return [[query itemSections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[[query itemSections] objectAtIndex:section] range].length;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MusicCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] init];
        [cell setRestorationIdentifier:@"MusicCell"];
    }
    
    cell.backgroundColor = UIColorFromRGBWithAlpha(0x4E5257, 0.3);
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.userInteractionEnabled = YES;
    cell.accessoryType = UITableViewCellAccessoryNone;
    return cell;
}

// Changes header views background color
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    view.tintColor = [UIColor clearColor];
    [view.layer setBorderWidth:0.5f];
    [view.layer setBorderColor:[UIColor blackColor].CGColor];
    view.frame = CGRectMake(view.frame.origin.x - 1, view.frame.origin.y, view.frame.size.width + 2, view.frame.size.height);
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    HeaderSongCellView *cell = [wholeTableView dequeueReusableHeaderFooterViewWithIdentifier:@"HeaderSong"];
    cell.title.text = [[query.itemSections objectAtIndex:section] title];
    return cell;
}
@end
