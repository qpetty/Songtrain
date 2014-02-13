//
//  ViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 1/21/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "MainViewController.h"
#import <CoreImage/CoreImage.h>

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    //Construct User Interface
    
    //self.view.backgroundColor = UIColorFromRGB(0x363636);
    
    //Sets up the navigationBar to be transparent, same as Background Image
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:UIColorFromRGB(0xebebeb), NSForegroundColorAttributeName, nil];
    [self setTitle:@"Station"];
    self.navigationController.delegate = self;

    //Blur Background Image and add to MainView
    CIImage *gaussBlurBackground = [[CIImage alloc] initWithImage:[UIImage imageNamed:@"splash.png"]];

    CIFilter *gaussianBlurFilter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [gaussianBlurFilter setValue:gaussBlurBackground forKey: @"inputImage"];
    [gaussianBlurFilter setValue:[NSNumber numberWithFloat: 8] forKey: @"inputRadius"];
    CIImage *resultImage = [gaussianBlurFilter valueForKey: @"outputImage"];
    UIImage *blurredImage = [[UIImage alloc] initWithCIImage:resultImage];

    newView = [[UIImageView alloc] initWithFrame:self.view.frame];
    newView.frame = CGRectMake(self.view.frame.origin.x - 30, self.view.frame.origin.y - 15, self.view.bounds.size.width * 1.5, self.view.bounds.size.height + 30);
    newView.image = blurredImage;
    [self.view addSubview:newView];

    //Insert Song View in the created CGRect
    CGRect location = CGRectMake(self.navigationController.navigationBar.bounds.origin.x,
                                     self.navigationController.navigationBar.bounds.origin.y + self.navigationController.navigationBar.bounds.size.height + [[UIApplication sharedApplication]statusBarFrame].size.height,
                                     self.view.bounds.size.width,
                                     ARTWORK_HEIGHT);
    musicPlayer = [MPMusicPlayerController iPodMusicPlayer];

    self.albumArtwork = [[CurrentSongView alloc] initWithPlayer:musicPlayer andFrame:location];
    self.albumArtwork.delegate = self;
    if ([musicPlayer nowPlayingItem]) {
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

    // Set up parallax animator
    animator = [[Animator alloc] init];

    //Multipeer Connectivity initialization
    service = SERVICE_TYPE;
    pid = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    
    peerArray = [[NSMutableArray alloc] init];
    mainTableView.dataSource = self;
    mainTableView.delegate = self;
    
    mainSession = [[MCSession alloc] initWithPeer:pid];
    mainSession.delegate = self;
    
    browse = [[MCNearbyServiceBrowser alloc] initWithPeer:pid serviceType:service];
    browse.delegate = self;


}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"Browsing for Peers...\n");
    [mainSession disconnect];
    [peerArray removeAllObjects];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"View did appear...\n");
    [mainTableView reloadData];
    [browse startBrowsingForPeers];
    mainSession.delegate = self;
    //[self.albumArtwork updateSongInfo:[musicPlayer nowPlayingItem]];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSLog(@"Stopped browsing for Peers...\n");
    [browse stopBrowsingForPeers];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSLog(@"View did Disappear...\n");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)createTrainPressed:(UIButton*)sender
{
    NSLog(@"Create new Train\n");
    ServerPlaylistViewController *incoming = [[ServerPlaylistViewController alloc] initWithSession:mainSession];
    [self.navigationController pushViewController:incoming animated:YES];
}

- (void)buttonPressed:(UIButton*)sender
{
    if (sender.tag == InfoButton) {
        NSLog(@"Info Button pressed\n");
        //TODO: Memory allocation, only want one InfoViewController
        infoView = [[InfoViewController alloc] initWithPlayer:musicPlayer];
        [self.navigationController pushViewController:infoView animated:YES];
    }
    else if (sender.tag == FavoriteButton) {
        NSLog(@"Favorite Button pressed\n");
    }
    else if (sender.tag == MuteButton) {
        NSLog(@"Mute Button pressed\n");
        
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"peerCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] init];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    if (peerArray.count > 0){
        cell.textLabel.text = [[peerArray objectAtIndex:[indexPath row]] displayName];
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
    
    [browse invitePeer:[peerArray objectAtIndex:[indexPath row]] toSession:mainSession withContext:nil timeout:0];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(peerArray.count > 0)
        return peerArray.count;
    else
        return 1;
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSLog(@"Found Peer: %@", peerID.displayName);
    if (![peerID.displayName isEqualToString:pid.displayName]) {
        NSLog(@"Added Peer: %@", peerID.displayName);
        dispatch_async(dispatch_get_main_queue(), ^{
            [peerArray addObject:peerID];
            [mainTableView reloadData];
        });
    }
}

-(void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"Lost Peer: %@", peerID.displayName);
    if (![peerID.displayName isEqualToString:pid.displayName]) {
        NSLog(@"Removed Peer: %@", peerID.displayName);
        
        //NSLog(@"Array size before: %d\n", peerArray.count);
        for (MCPeerID *peer in peerArray) {
            if ([peer.displayName isEqualToString:peerID.displayName]) {
                [peerArray removeObject:peer];
                break;
            }
        }
        [peerArray removeObjectIdenticalTo:peerID];
        //NSLog(@"Array size after: %d\n", peerArray.count);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [mainTableView reloadData];
        });
    }
}

-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnecting) {
        NSLog(@"Connecting to %@", peerID.displayName);
    } else if (state == MCSessionStateConnected) {
        NSLog(@"Connected to %@", peerID.displayName);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController pushViewController:[[ClientPlaylistViewController alloc] initWithSession:mainSession andServerPeerID:peerID] animated:YES];
            [peerArray removeAllObjects];
            [mainTableView reloadData];
        });
    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"Disconnected from %@", peerID.displayName);
    }
}

-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"Got Stream: %@  from %@\n", streamName, [peerID displayName]);
}

-(void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    
}

-(void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    //NSLog(@"Here: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
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


-(id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {

    // Use this until I think of a better way.
    newView.image = nil;

    switch (operation) {
        case UINavigationControllerOperationPush:
            return animator;
        case UINavigationControllerOperationPop:
            return animator;
        default: return nil;
    }
}


@end
