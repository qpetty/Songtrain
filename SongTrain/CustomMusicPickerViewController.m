//
//  CustomMusicPickerViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 4/7/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "CustomMusicPickerViewController.h"

@interface CustomMusicPickerViewController (){
    UITableView *wholeTableView;
    NSArray *queryResults;
    NSArray *musicItems;
}

@end

@implementation CustomMusicPickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)init{
    self = [super init];
    if (self) {
        [self myInit];
    }
    return self;
}

- (void)myInit
{
    wholeTableView = [[UITableView alloc] init];
    wholeTableView.dataSource = self;
    wholeTableView.delegate = self;
    
    MPMediaQuery *everything = [[MPMediaQuery alloc] init];
    
    MPMediaPropertyPredicate *artistPredicate = [MPMediaPropertyPredicate predicateWithValue:@"The Alan Parsons Project" forProperty:MPMediaItemPropertyArtist];
    [everything addFilterPredicate:artistPredicate];
    
    queryResults = [everything items];
    
    /*
    void (^checkDRM)(id, NSUInteger, BOOL*) = ^(id obj, NSUInteger idx, BOOL *stop) {
        
        MPMediaItem* item = (MPMediaItem*)obj;
        if (![item valueForProperty:MPMediaItemPropertyAssetURL]) {
            //
        }
        
        //NSLog(@"%d\n",[(MPMediaItem*)obj valueForProperty:MPMediaItemPropertyAssetURL]);
    };
    
    //[queryResults enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:checkDRM];
    [queryResults enumerateObjectsUsingBlock:checkDRM];
    */
    musicItems = [everything items];
    
    NSLog(@"array size %d\n", musicItems.count);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self myInit];
    [self.view addSubview:wholeTableView];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    wholeTableView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
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
    return [musicItems count];
}


 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
 {
     UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MusicCell"];
 
     if (!cell) {
         cell = [[UITableViewCell alloc] init];
         cell.backgroundColor = [UIColor clearColor];
         cell.textLabel.textColor = [UIColor blackColor];
         [cell setRestorationIdentifier:@"MusicCell"];
     }
     if ([[musicItems objectAtIndex:[indexPath row]] valueForProperty:MPMediaItemPropertyAssetURL]) {
         cell.textLabel.text = [[musicItems objectAtIndex:[indexPath row]] valueForProperty:MPMediaItemPropertyTitle];
         cell.userInteractionEnabled = YES;
     }
     else{
         cell.textLabel.text = @"DRM shit";
         cell.userInteractionEnabled = NO;
     }
     cell.accessoryType = UITableViewCellAccessoryNone;
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
