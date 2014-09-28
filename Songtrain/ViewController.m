//
//  ViewController.m
//  Songtrain
//
//  Created by Quinton Petty on 9/18/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "ViewController.h"
#import <CoreImage/CoreImage.h>
#import "QPMusicPlayerController.h"
#import "SongTableViewCell.h"
#import "PeerTableViewCell.h"
#import "QPSessionManager.h"

#import "NearbyTrainViewController.h"

#ifndef HEX_COLOR
#define HEX_COLOR
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define UIColorFromRGBWithAlpha(rgbValue, alp) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha: alp]
#endif

@interface ViewController ()

@end

@implementation ViewController {
    QPMusicPlayerController *musicPlayer;
    MusicPickerViewController *musicPicker;
    
    QPSessionManager *sessionManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.songTableView registerNib:[UINib nibWithNibName:@"SongTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"SongCell"];
    [self.songTableView registerNib:[UINib nibWithNibName:@"PeerTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"PeerCell"];
    [self.peerTableView registerNib:[UINib nibWithNibName:@"PeerTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"PeerCell"];

    self.nearbyTrainsModal = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self.nearbyTrainsModal registerNib:[UINib nibWithNibName:@"TrainCellView" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"TrainCell"];
    self.nearbyTrainsModal.delegate = self;
    self.nearbyTrainsModal.dataSource = self;

    
    self.backgroundImage = [[UIImageView alloc] initWithFrame:self.view.frame];
    self.backgroundOverlay = [[UIImageView alloc] initWithFrame:self.view.frame];
    
    musicPlayer = [QPMusicPlayerController sharedMusicPlayer];
    [musicPlayer resetToServer];
    
    sessionManager = [QPSessionManager sessionManager];
    [sessionManager createServer];
    
    musicPicker = [[MusicPickerViewController alloc] init];
    musicPicker.delegate = self;

    self.peerTableView.hidden = YES;
    
    self.currentSongTitle.textColor = UIColorFromRGBWithAlpha(0xFFFFFF, 1.0);
    self.currentSongArtist.textColor = UIColorFromRGBWithAlpha(0xFFFFFF, 1.0);
    self.mainTitle.textColor = UIColorFromRGBWithAlpha(0xFFFFFF, 1.0);
    //self.currentSongTitle.text = @"Really Long Current Song Title";
    [self configureMarqueeLabel:self.currentSongTitle];
    [self configureMarqueeLabel:self.currentSongArtist];
    self.currentSongTitle.text = @"   ";
    self.currentSongArtist.text = @"  ";
}

-(void)configureMarqueeLabel:(MarqueeLabel*)label {
    label.rate = 75.0;
    label.fadeLength = 10.0;
    label.marqueeType = MLContinuous;
    label.continuousMarqueeExtraBuffer = 25.0;
    label.animationDelay = 5.0;
}

-(UIImage *)blurImage:(UIImage *)image
{
    CIImage *imageToBlur = [CIImage imageWithCGImage:image.CGImage];
    CIFilter *gaussianBlurFilter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [gaussianBlurFilter setValue:imageToBlur forKey: @"inputImage"];
    [gaussianBlurFilter setValue:[NSNumber numberWithFloat: 1] forKey: @"inputRadius"];
    CIImage *resultImage = [gaussianBlurFilter valueForKey: @"outputImage"];
    return [[UIImage alloc] initWithCIImage:resultImage];
}

- (UIImage*)cropAlbumImage:(UIImage*)image withScreenRect:(CGRect)screenSize
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake((image.size.width - screenSize.size.width) / 2, 0, screenSize.size.width, screenSize.size.height));
    
    return [UIImage imageWithCGImage:imageRef];
}

-(void)viewDidLayoutSubviews {
    
    [self.backgroundOverlay setFrame:self.view.frame];

    self.backgroundOverlay.backgroundColor = UIColorFromRGBWithAlpha(0x111111, .8);
    
    [self.view addSubview:self.backgroundOverlay];
    [self.view sendSubviewToBack:self.backgroundOverlay];
    
    [self.backgroundImage setFrame:CGRectMake(self.view.frame.origin.x - 10, self.view.frame.origin.y - 10, self.view.frame.size.width + 20, self.view.frame.size.height + 20)];
    
    self.backgroundImage.image = [self blurImage: [self cropAlbumImage:self.currentAlbumArtwork.image withScreenRect:self.view.frame]];

    [self.view addSubview:self.backgroundImage];
    [self.view sendSubviewToBack:self.backgroundImage];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.mainTitle.text = sessionManager.server.displayName;
    [sessionManager addObserver:self forKeyPath:@"server" options:NSKeyValueObservingOptionNew context:nil];
    [sessionManager addObserver:self forKeyPath:@"peerArray" options:NSKeyValueObservingOptionNew context:nil];
    [sessionManager addObserver:self forKeyPath:@"connectedPeerArray" options:NSKeyValueObservingOptionNew context:nil];
    [musicPlayer addObserver:self forKeyPath:@"playlist" options:NSKeyValueObservingOptionNew context:nil];
    [musicPlayer addObserver:self forKeyPath:@"currentSong" options:NSKeyValueObservingOptionNew context:nil];
    [musicPlayer addObserver:self forKeyPath:@"currentSongTime" options:NSKeyValueObservingOptionNew context:nil];
    [self updatePlayOrPauseImage];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [sessionManager removeObserver:self forKeyPath:@"server"];
    [sessionManager removeObserver:self forKeyPath:@"connectedPeerArray"];
    [sessionManager removeObserver:self forKeyPath:@"peerArray"];
    [musicPlayer removeObserver:self forKeyPath:@"playlist"];
    [musicPlayer removeObserver:self forKeyPath:@"currentSong"];
    [musicPlayer removeObserver:self forKeyPath:@"currentSongTime"];
}


-(IBAction)browseForOthers:(id)sender {
    [sessionManager startBrowsingForTrains];

    self.nearbyTrainsModal.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:self.nearbyTrainsModal];
    
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:3 options:UIViewAnimationOptionTransitionNone animations:^{
        [self.nearbyTrainsModal setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height)];
    } completion:^(BOOL finished) {
    }];
    
}

-(void)finishBrowsingForOthers
{
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:3 options:UIViewAnimationOptionTransitionNone animations:^{
        [self.nearbyTrainsModal setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    } completion:^(BOOL finished) {
    }];
}

-(void)closePresentationController {
    [sessionManager stopBrowsingForTrains];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)skip:(id)sender {
    [musicPlayer skip];
}

-(IBAction)playAndPause:(id)sender {
    [musicPlayer play];
    [self updatePlayOrPauseImage];
}

-(void)updatePlayOrPauseImage {
    [self.playOrPauseButton setImage:musicPlayer.isRunning ? [UIImage imageNamed:@"pause"] :[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
}

-(void)updateCurrentTime {
    NSRange currentTime = musicPlayer.currentSongTime;
    //songProgress.progress = (float)currentTime.location / (float)currentTime.length;
    [self updateLabel:self.currentTime withSeconds:currentTime.location];
    [self updateLabel:self.totalTime withSeconds:currentTime.length];
}

-(void)updateLabel:(UILabel*)label withSeconds:(NSUInteger)sec {
    NSUInteger minutes = 0;
    
    while (sec >= 60) {
        minutes++;
        sec -= 60;
    }
    
    label.text = [NSString stringWithFormat:@"%lu:%.2lu", minutes, sec];
}

#pragma mark UISegmentedControl

-(IBAction)switchTableView:(id)sender {
    if (self.tracksAndPassengers.selectedSegmentIndex == 0) {
        self.songTableView.hidden = NO;
        self.peerTableView.hidden = YES;
    }
    else {
        self.songTableView.hidden = YES;
        self.peerTableView.hidden = NO;
    }
}

#pragma mark PopoverPresentationControllerDelegate

-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationCustom;
}

-(UIViewController *)presentationController:(UIPresentationController *)controller viewControllerForAdaptivePresentationStyle:(UIModalPresentationStyle)style {
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller.presentedViewController];
    controller.presentedViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(closePresentationController)];
    return navController;
}

#pragma mark MusicPickerDelegate

-(IBAction)openMusicPicker:(id)sender {
    [self presentViewController:musicPicker animated:YES completion:nil];
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    NSMutableArray *newSongs = [[NSMutableArray alloc] init];
    for (MPMediaItem *item in mediaItemCollection.items) {
        LocalSong *tempSong = [[LocalSong alloc] initWithOutputASBD:*(musicPlayer.audioFormat) andItem:item];
        [newSongs addObject:tempSong];
    }

    [self dismissViewControllerAnimated:YES completion:^{
        for (Song *song in newSongs) {
            if (sessionManager.currentRole == ClientConnection) {
                [sessionManager addSongToServer:song];
            }
            else {
                [sessionManager addSongToAllPeers:song];
                [musicPlayer addSongToPlaylist:song];
            }
        }
    }];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView != self.nearbyTrainsModal) {
        return;
    }
    [sessionManager connectToPeer:[sessionManager.peerArray objectAtIndex:indexPath.row]];
    [self finishBrowsingForOthers];
}

#pragma mark TableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows = 0;
    if (tableView == self.songTableView) {
        numRows = musicPlayer.playlist.count;
    } else if (tableView == self.peerTableView) {
        numRows = sessionManager.connectedPeerArray.count;
    } else if (tableView == self.nearbyTrainsModal) {
        NSLog(@"Found %lu trains", sessionManager.peerArray.count);
        return sessionManager.peerArray.count;
    }
    return numRows < 1 ? 1 : numRows;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (tableView == self.songTableView) {
        cell = [self songTableView:tableView withIndexPath:indexPath];
    }
    else if (tableView == self.peerTableView) {
        cell = [self peerTableView:tableView withIndexPath:indexPath];
    } else if (tableView == self.nearbyTrainsModal) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"TrainCell" forIndexPath:indexPath];
        MCPeerID *peerID = [sessionManager.peerArray objectAtIndex:indexPath.row];
        cell.textLabel.text = peerID.displayName;
    }
    return cell;
}

-(UITableViewCell *)songTableView:(UITableView *)tableView withIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *finalCell = nil;
    
    if (musicPlayer.playlist.count < 1){
        PeerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PeerCell"];
        if (!cell) {
            NSLog(@"Something went wrong because we dont have a tableviewcell");
        }
        cell.mainLabel.text = @"No Songs";
        finalCell = cell;
    }
    else {
        SongTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SongCell"];
        if (!cell) {
            NSLog(@"Something went wrong because we dont have a tableviewcell");
        }
        
        Song *oneSong = [musicPlayer.playlist objectAtIndex:indexPath.row];
        cell.mainLabel.text = oneSong.title;
        cell.detailLabel.text = oneSong.artistName;
        finalCell = cell;
    }
    
    return finalCell;
}

-(UITableViewCell *)peerTableView:(UITableView *)tableView withIndexPath:(NSIndexPath *)indexPath {
    PeerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PeerCell"];
    if (!cell) {
        NSLog(@"Something went wrong because we dont have a tableviewcell");
    }
    
    if (sessionManager.connectedPeerArray.count < 1){
        cell.mainLabel.text = @"No Passengers";
    }
    else {
        MCPeerID *onePeer = [sessionManager.connectedPeerArray objectAtIndex:indexPath.row];
        cell.mainLabel.text = onePeer.displayName;
    }
    
    return cell;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"playlist"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.songTableView reloadData];
        });
    }
    else if ([keyPath isEqualToString:@"connectedPeerArray"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.peerTableView reloadData];
        });
    }
    else if ([keyPath isEqualToString:@"currentSong"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Change title");
            self.currentSongTitle.text = musicPlayer.currentSong.title;
            self.currentSongArtist.text = musicPlayer.currentSong.artistName;
            self.currentAlbumArtwork.image = musicPlayer.currentSong.albumImage == nil ? [UIImage imageNamed:@"albumart_default"] : musicPlayer.currentSong.albumImage;
            self.backgroundImage.image = [self blurImage:self.currentAlbumArtwork.image];
        });
    }
    else if ([keyPath isEqualToString:@"currentSongTime"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateCurrentTime];
        });
    }
    else if ([keyPath isEqualToString:@"server"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.mainTitle.text = sessionManager.server.displayName;
            [self updatePlayOrPauseImage];
        });
    } else if ([keyPath isEqualToString:@"peerArray"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.nearbyTrainsModal reloadData];
        });
    }
}




@end
