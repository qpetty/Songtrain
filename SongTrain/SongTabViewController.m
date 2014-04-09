//
//  SongTabViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 4/7/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "SongTabViewController.h"

@interface SongTabViewController ()

@end

@implementation SongTabViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)initWithQuery:(MPMediaQuery*)query
{
    self = [self init];
    if (self) {
        if (!query) {
            query = [[MPMediaQuery alloc] init];
            
            /*
            MPMediaPropertyPredicate *artistPredicate = [MPMediaPropertyPredicate predicateWithValue:@"The Alan Parsons Project" forProperty:MPMediaItemPropertyArtist];
            [query addFilterPredicate:artistPredicate];
             */
        }
        
        displayItems = [query items];
    }
    return self;
}

    /*
     queryResults = [query items];
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
    return [super numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [super tableView:tableView numberOfRowsInSection:section];
}


 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
 {
     UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
 
     if ([[displayItems objectAtIndex:[indexPath row]] valueForProperty:MPMediaItemPropertyAssetURL]) {
         cell.textLabel.text = [[displayItems objectAtIndex:[indexPath row]] valueForProperty:MPMediaItemPropertyTitle];
         cell.textLabel.textColor = [UIColor blackColor];
         cell.userInteractionEnabled = YES;
     }
     else{
         cell.textLabel.text = @"DRM shit";
         cell.textLabel.textColor = [UIColor redColor];
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
