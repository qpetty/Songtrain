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

-(id)initWithQuery:(MPMediaQuery*)mediaQuery
{
    self = [self init];
    if (self) {
        if (mediaQuery) {
            query = mediaQuery;
        }
        else{
            query = [[MPMediaQuery alloc] init];
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

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    NSMutableArray *titles = [[NSMutableArray alloc] init];
    
    //[titles addObject:UITableViewIndexSearch];
    
    for (MPMediaQuerySection *section in query.itemSections) {
        [titles addObject:section.title];
    }
    return titles;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[[query itemSections] objectAtIndex:section] title];
}

 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
 {
     UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
 
     NSUInteger ndx = [[[query itemSections] objectAtIndex:indexPath.section] range].location + indexPath.row;
     
     if ([[displayItems objectAtIndex:ndx] valueForProperty:MPMediaItemPropertyAssetURL]) {
         cell.textLabel.text = [[displayItems objectAtIndex:ndx] valueForProperty:MPMediaItemPropertyTitle];
         cell.textLabel.textColor = [UIColor whiteColor];
         cell.userInteractionEnabled = YES;
         if ([((MusicPickerViewController*)self.tabBarController) isItemSelected:[displayItems objectAtIndex:ndx]]) {
             cell.textLabel.textColor = UIColorFromRGB(0x7FA8D7);
         }
         else {
             cell.backgroundColor = UIColorFromRGBWithAlpha(0x4E5257, 0.3);
         }
         //NSLog(@"%@\n", [((MusicPickerViewController*)self.tabBarController) isItemSelected:[displayItems objectAtIndex:ndx]] ? @"YES" : @"NO");
     }
     else{
         cell.textLabel.text = [[displayItems objectAtIndex:ndx] valueForProperty:MPMediaItemPropertyTitle];
         cell.textLabel.textColor = UIColorFromRGB(0x656A71);
         cell.userInteractionEnabled = NO;
     }
     
     cell.accessoryType = UITableViewCellAccessoryNone;
     return cell;
 }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger ndx = [[[query itemSections] objectAtIndex:indexPath.section] range].location + indexPath.row;
    
    if ([((MusicPickerViewController*)self.tabBarController) isItemSelected:[displayItems objectAtIndex:ndx]]) {
        [((MusicPickerViewController*)self.tabBarController) removeItem:[displayItems objectAtIndex:ndx]];
    }
    else {
        [((MusicPickerViewController*)self.tabBarController) addItem:[displayItems objectAtIndex:ndx]];
    }
    [tableView reloadData];
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
