//
//  ViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 1/21/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    //Construct User Interface
    
    self.view.backgroundColor = UIColorFromRGB(0x363636);
    
    //Sets up the navigationBar to be transparent, same as Background Image
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:UIColorFromRGB(0xebebeb), NSForegroundColorAttributeName, nil];
    [self setTitle:@"Station"];

    //Blur Background Image and add to MainView
    CIImage *gaussBlurBackground = [[CIImage alloc] initWithImage:[UIImage imageNamed:@"splash.png"]];

    CIFilter *gaussianBlurFilter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [gaussianBlurFilter setValue:gaussBlurBackground forKey: @"inputImage"];
    [gaussianBlurFilter setValue:[NSNumber numberWithFloat: 8] forKey: @"inputRadius"];
    CIImage *resultImage = [gaussianBlurFilter valueForKey: @"outputImage"];
    UIImage *blurredImage = [[UIImage alloc] initWithCIImage:resultImage];

    UIImageView *newView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    newView.frame = CGRectMake(self.view.bounds.origin.x - 15, self.view.bounds.origin.y - 15, self.view.bounds.size.width + 30, self.view.bounds.size.height + 30);
    newView.image = blurredImage;
    [self.view addSubview:newView];

    //Insert Song View in the created CGRect
    CGRect location = CGRectMake(self.navigationController.navigationBar.bounds.origin.x,
                                     self.navigationController.navigationBar.bounds.origin.y + self.navigationController.navigationBar.bounds.size.height + [[UIApplication sharedApplication]statusBarFrame].size.height,
                                     self.view.bounds.size.width,
                                     ARTWORK_HEIGHT);
    
    sessionManager = [QPSessionManager sessionManager];
    sessionManager.delegate = self;
    musicPlayer = [QPMusicPlayerController musicPlayer];
    
    self.albumArtwork = [[CurrentSongView alloc] initWithFrame:location];
    self.albumArtwork.delegate = self;

    if (musicPlayer.currentSong) {
        [self.albumArtwork updateSongInfo:musicPlayer.currentSong];
        [self.view addSubview:self.albumArtwork];
    } else {
        // Put Label here.
        songNotPlayingHeader = [UIImage imageNamed:@"name.png"];
        UIImageView *header = [[UIImageView alloc] initWithImage:songNotPlayingHeader];
        header.frame = CGRectMake(self.view.bounds.size.width/4, self.view.bounds.size.height/6, self.view.bounds.size.width/2, self.view.bounds.size.height/15);
        [self.view addSubview:header];
    }


    
    //Setup create train button
    location = CGRectMake(self.view.bounds.origin.x,
                          self.albumArtwork.frame.origin.y + self.albumArtwork.frame.size.height,
                          self.view.bounds.size.width,
                          SINGLE_TABLEVIEWCELL_HEIGHT);
    self.createTrainButton = [[SingleCellButton alloc] initWithFrame:location];
    [self.view addSubview:self.createTrainButton];
    [self.createTrainButton setTitle:@"Create New Train" forState:UIControlStateNormal];
    self.createTrainButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [self.createTrainButton addTarget:self action:@selector(createTrainPressed:) forControlEvents:UIControlEventTouchDown];
    
    //Create TableView
    location = CGRectMake(self.view.frame.origin.x,
                          self.createTrainButton.frame.origin.y + self.createTrainButton.frame.size.height + HEIGHT_BEFORE_TABLEVIEW,
                          self.view.frame.size.width,
                          self.view.frame.size.height - self.createTrainButton.frame.origin.y - self.createTrainButton.frame.size.height - HEIGHT_BEFORE_TABLEVIEW - self.albumArtwork.frame.origin.y);
    mainTableView = [[GrayTableView alloc] initWithFrame:location];
    [self.view addSubview:mainTableView];
    
    mainTableView.dataSource = self;
    mainTableView.delegate = self;
    
    
    //TableView Title
    location = CGRectMake(self.view.bounds.origin.x + 15,
                          mainTableView.frame.origin.y - 20,
                          self.view.bounds.size.width,
                          14);
    label = [[UILabel alloc] initWithFrame:location];
    label.textColor = [UIColor whiteColor];
    [label setFont:[UIFont systemFontOfSize:12]];
    label.text = @"NEARBY TRAINS";
    
    [self.view addSubview:label];

    //Add Control Bar at bottom of the screen
    location = CGRectMake(mainTableView.frame.origin.x,
                          mainTableView.frame.origin.y + mainTableView.frame.size.height,
                          self.view.frame.size.width,
                          self.albumArtwork.frame.origin.y);
    
    panel = [[ControlPanel alloc] initWithFrame:location];
    panel.delegate = self;
    [self.view addSubview:panel];
    
    // Hide annoying line
    self.navBarHairlineImageView = [self findHairlineImageViewUnder:self.navigationController.navigationBar];
    self.navBarHairlineImageView.hidden = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [sessionManager startBrowsing];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //[sessionManager stopBrowsing];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)createTrainPressed:(UIButton*)sender
{
    NSLog(@"Create new Train\n");
    ServerPlaylistViewController *newViewController = [[ServerPlaylistViewController alloc] init];
    sessionManager.delegate = newViewController;
    [sessionManager stopBrowsing];
    [self.navigationController pushViewController:newViewController animated:YES];
}

- (void)buttonPressed:(UIButton *)sender withSong:(Song *)song
{
    if (sender.tag == InfoButton) {
        NSLog(@"Info Button pressed\n");
        //TODO: Memory allocation, only want one InfoViewController
        infoView = [[InfoViewController alloc] initWithSong:song];
        [self.navigationController pushViewController:infoView animated:YES];
    }

}

- (void)availablePeersUpdated:(NSMutableArray *)peerArray
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainTableView reloadData];
    });
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"peerCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] init];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    if (sessionManager.peerArray.count > 0){
        cell.textLabel.text = [[sessionManager.peerArray objectAtIndex:[indexPath row]] displayName];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.userInteractionEnabled = YES;
    }
    else{
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.userInteractionEnabled = NO;
        cell.textLabel.text = @"No Nearby Trains";
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selected train: %@\n", [tableView cellForRowAtIndexPath:indexPath].textLabel.text);
    
    ClientPlaylistViewController *nextView = [[ClientPlaylistViewController alloc] init];
    sessionManager.delegate = nextView;
    
    [sessionManager connectToPeer:[sessionManager.peerArray objectAtIndex:[indexPath row]]];
    [sessionManager stopBrowsing];
    [self.navigationController pushViewController:nextView animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(sessionManager.peerArray.count > 0)
        return sessionManager.peerArray.count;
    else
        return 1;
}

- (UIImageView *)findHairlineImageViewUnder:(UIView *)view {
   if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
      return (UIImageView *)view;
   }
   for (UIView *subview in view.subviews) {
      UIImageView *imageView = [self findHairlineImageViewUnder:subview];
      if (imageView) {
         return imageView;
      }
   }
   return nil;
}


@end
