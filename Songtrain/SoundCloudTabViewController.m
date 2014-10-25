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
    SCLoginViewController *login;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        //[SCSoundCloud removeAccess];
        [self setupSoundCloud];
        
        if ([SCSoundCloud account] == nil) {
            [self getAuthViewController];
        } else {
            [self getFavorites];
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
    [self getFavorites];
}

-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    login.view.frame = CGRectMake(self.view.frame.origin.x,
                                  self.view.frame.origin.y + 32.0,
                                  self.view.frame.size.width,
                                  self.view.frame.size.height);
}

- (void)getFavorites {
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
                tracks = (NSArray *)jsonResponse;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.wholeTableView reloadData];
                    NSLog(@"Updated favorites");
                });
            }
        };
        
        NSString *resourceURL = @"https://api.soundcloud.com/me/favorites.json";
        [SCRequest performMethod:SCRequestMethodGET onResource:[NSURL URLWithString:resourceURL] usingParameters:nil withAccount:[SCSoundCloud account] sendingProgressHandler:nil responseHandler:handler];
    } else {
        tracks = nil;
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
            [self getFavorites];
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
