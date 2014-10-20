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

@interface SoundCloudTabViewController ()

@end

@implementation SoundCloudTabViewController {
    NSArray *tracks;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"SoundCloud";
    tracks = nil;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
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
            });
        }
    };
    
    NSString *resourceURL = @"https://api.soundcloud.com/me/favorites.json";
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:resourceURL]
             usingParameters:nil
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:handler];
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
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = UIColorFromRGBWithAlpha(0x4E5257, 0.3);
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    cell.textLabel.text = [tracks objectAtIndex:indexPath.row][@"title"];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.userInteractionEnabled = YES;
    
    SoundCloudSong *newSong = [[SoundCloudSong alloc] initWithURL:[NSURL URLWithString:[tracks objectAtIndex:indexPath.row][@"uri"]]];
    if ([self.delegate isItemSelected:newSong]) {
        cell.textLabel.textColor = UIColorFromRGBWithAlpha(0x7FA8D7, 1.0);
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SoundCloudSong *newSong = [[SoundCloudSong alloc] initWithSoundCloudDictionary:[tracks objectAtIndex:indexPath.row]];
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
