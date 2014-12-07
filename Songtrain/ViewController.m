//
//  ViewController.m
//  Songtrain
//
//  Created by Quinton Petty on 9/18/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "ViewController.h"
#import <CoreImage/CoreImage.h>
#import "SongTableViewCell.h"
#import "PeerTableViewCell.h"
#import "AnimatedCollectionViewFlowLayout.h"
#import "SoundCloudSong.h"

#import "XBCurlView.h"

#define ITUNES_SEARCH_API_AFFILIATE_TOKEN @"11lMLF"
#define ITUNES_SEARCH_API_CAMPAIGN_TOKEN @""
#define STATIC_NEARBY_TRAIN_CELLS 1

@interface ViewController ()

@end

@implementation ViewController {
    QPMusicPlayerController *musicPlayer;
    MusicPickerViewController *musicPicker;
    
    QPSessionManager *sessionManager;
    BOOL editingTableViews;
    UIActivityIndicatorView *loadingIcon;
    
    UIImageView *backgroundImage;
    UIImageView *backgroundOverlay;
    
    UICollectionView *nearbyTrainsModal;
    UIView *nearbyTrainBackground;
    UIButton *nearbyTrainCancelButton;
    SKStoreProductViewController *storeController;
    NSString *currentSongID;
    
    XBCurlView *curlView;
    UIView *transparent;
    BOOL shouldShowPurchaseButton, curled;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    shouldShowPurchaseButton = curled = NO;
    
    [self.songTableView registerNib:[UINib nibWithNibName:@"SongTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"SongCell"];
    [self.songTableView registerNib:[UINib nibWithNibName:@"PeerTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"PeerCell"];
    [self.peerTableView registerNib:[UINib nibWithNibName:@"PeerTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"PeerCell"];

    UICollectionViewFlowLayout *layout = [[AnimatedCollectionViewFlowLayout alloc] init];
    [layout setItemSize:CGSizeMake(self.view.frame.size.width, 50)];
    nearbyTrainsModal = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    [nearbyTrainsModal registerNib:[UINib nibWithNibName:@"AnimatedCollectionViewCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"AnimatedPeerCell"];
    nearbyTrainsModal.delegate = self;
    nearbyTrainsModal.dataSource = self;
    nearbyTrainsModal.backgroundColor = UIColorFromRGBWithAlpha(0x111111, 0.4);
    nearbyTrainsModal.backgroundView = [[UIView alloc] initWithFrame:nearbyTrainsModal.frame];
    UITapGestureRecognizer *cancelBrowsingTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(cancelBrowsingForOthersTap:)];
    nearbyTrainsModal.backgroundView.gestureRecognizers = @[cancelBrowsingTap];
    

    backgroundImage = [[UIImageView alloc] initWithFrame:self.view.frame];
    backgroundImage.contentMode = UIViewContentModeScaleAspectFill;
    backgroundOverlay = [[UIImageView alloc] initWithFrame:self.view.frame];
    nearbyTrainBackground = [[UIView alloc] initWithFrame:self.view.frame];
    nearbyTrainBackground.backgroundColor = UIColorFromRGBWithAlpha(0x111111, .8);
    nearbyTrainCancelButton = [[UIButton alloc] init];
    [nearbyTrainCancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [nearbyTrainCancelButton setTitleColor:UIColorFromRGBWithAlpha(0x7FA8D7, 1.0) forState:UIControlStateNormal];
    nearbyTrainCancelButton.frame = CGRectMake(self.view.frame.size.width/2.0 - 30, (self.view.frame.size.height * 2)/3.0, 60, 20);
    [nearbyTrainCancelButton addTarget:self action:@selector(cancelBrowsingForOthersTap:) forControlEvents:UIControlEventTouchUpInside];
    loadingIcon = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [nearbyTrainBackground addSubview:loadingIcon];
    
    musicPlayer = [QPMusicPlayerController sharedMusicPlayer];
    musicPlayer.delegate = self;
    
    sessionManager = [QPSessionManager sessionManager];
    sessionManager.browsingDelegate = self;
    sessionManager.sessionDelegate = self;
    [sessionManager createServer];
    
    musicPicker = [[MusicPickerViewController alloc] init];
    musicPicker.delegate = self;

    self.peerTableView.hidden = YES;
    
    self.currentSongTitle.textColor = UIColorFromRGBWithAlpha(0xFFFFFF, 1.0);
    self.currentSongArtist.textColor = UIColorFromRGBWithAlpha(0xFFFFFF, 1.0);
    self.mainTitle.textColor = UIColorFromRGBWithAlpha(0xFFFFFF, 1.0);
    
    self.currentSongTitle.text = @"   ";
    self.currentSongArtist.text = @"  ";
    [self configureMarqueeLabel:self.currentSongTitle];
    [self configureMarqueeLabel:self.currentSongArtist];
    
    //Removes the separators below the last row of the tableviews
    self.songTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.peerTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    editingTableViews = NO;
    
    self.streamingServiceIcon.hidden = YES;
}


- (void)cancelBrowsingForOthersTap:(id)sender {
    [self finishBrowsingForOthers:NO];
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
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur" keysAndValues:kCIInputImageKey, imageToBlur, @"inputRadius", @(3), nil];
    CIImage *outputImage = filter.outputImage;
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef resultImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    UIImage *finalImage = [UIImage imageWithCGImage:resultImage];
    CFRelease(resultImage);
    
    return finalImage;
}

- (UIImage*)cropAlbumImage:(UIImage*)image withScreenRect:(CGRect)screenSize
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake((image.size.width - screenSize.size.width) / 2, 0, screenSize.size.width, screenSize.size.height));
    UIImage *imageToRet = [UIImage imageWithCGImage:imageRef];
    CFRelease(imageRef);
    return imageToRet;
}

-(void)viewDidLayoutSubviews {
    [backgroundOverlay setFrame:self.view.frame];
    backgroundOverlay.backgroundColor = UIColorFromRGBWithAlpha(0x111111, .8);
    
    [self.view addSubview:backgroundOverlay];
    [self.view sendSubviewToBack:backgroundOverlay];
    
    backgroundImage.image = [self blurImage:self.currentAlbumArtwork.image];

    [self.view addSubview:backgroundImage];
    [self.view sendSubviewToBack:backgroundImage];
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
    [musicPlayer addObserver:self forKeyPath:@"currentSong" options:NSKeyValueObservingOptionNew context:nil];
    [musicPlayer addObserver:self forKeyPath:@"currentSongTime" options:NSKeyValueObservingOptionNew context:nil];
    [musicPlayer addObserver:self forKeyPath:@"currentSong.albumImage" options:NSKeyValueObservingOptionNew context:nil];
    [self updatePlayOrPauseImage];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    __weak Song *weakSong = musicPlayer.currentSong;
    
    self.onScreen = YES;
    [self updateCurrentSong:weakSong];
    [self updateImage:weakSong.albumImage];

    [self showPurchaseButton];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.onScreen = NO;
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [sessionManager removeObserver:self forKeyPath:@"server"];
    [sessionManager removeObserver:self forKeyPath:@"peerArray"];
    [musicPlayer removeObserver:self forKeyPath:@"currentSong"];
    [musicPlayer removeObserver:self forKeyPath:@"currentSongTime"];
    [musicPlayer removeObserver:self forKeyPath:@"currentSong.albumImage"];
}

#pragma mark Browsing Popup

-(IBAction)browseForOthers:(id)sender {
    nearbyTrainsModal.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    
    [self.view addSubview:nearbyTrainBackground];
    [self.view addSubview:nearbyTrainsModal];
    
    [nearbyTrainsModal setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height)];
    [nearbyTrainsModal reloadItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]]];
    AnimatedCollectionViewCell *cell = (AnimatedCollectionViewCell *)[nearbyTrainsModal cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    cell.peerName.alpha = 0.0;
    
    // Delay inserting after first row insert for drop-down animation
    float delay = .2;
    dispatch_time_t delaydispatch = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
    
    dispatch_after(delaydispatch, dispatch_get_main_queue(), ^(void){
        [UIView animateWithDuration:.3 animations:^{
            cell.peerName.alpha = 1.0;
            [sessionManager startBrowsingForTrains];
        }];
    });
}

-(void)finishBrowsingForOthers:(BOOL)somethingSelected
{
    [sessionManager stopBrowsingForTrains];
    [self.browseForOtherTrains setEnabled:NO];
    
    [UIView animateWithDuration:.3 delay:0 usingSpringWithDamping:1 initialSpringVelocity:-2 options:UIViewAnimationOptionTransitionNone animations:^{
        [nearbyTrainsModal setAlpha:0.0];
    } completion:^(BOOL finished) {
        [nearbyTrainsModal setAlpha:1.0];
        [nearbyTrainsModal removeFromSuperview];
        [nearbyTrainsModal reloadData];
        [self.browseForOtherTrains setEnabled:YES];
    }];
    
    if (somethingSelected == NO) {
        [self removeLoadingScreen];
    } else {
        loadingIcon.center = nearbyTrainBackground.center;
        [loadingIcon startAnimating];
        [nearbyTrainBackground addSubview:nearbyTrainCancelButton];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }

}

-(void)removeLoadingScreen {
    [loadingIcon stopAnimating];
    [nearbyTrainCancelButton removeFromSuperview];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [nearbyTrainBackground removeFromSuperview];
}

-(void)skipPressed:(UIButton *)sender {
    [musicPlayer skip];
}

-(void)playOrPausedPressed:(UIButton *)sender {
    [musicPlayer play];
    [self updatePlayOrPauseImage];
}

-(void)updatePlayOrPauseImage {
    [self.controlBar currentlyPlaying:musicPlayer.isRunning];
}

-(void)updateCurrentTime {
    NSRange currentTime = musicPlayer.currentSongTime;
    self.progressBar.progress = (float)currentTime.location / (float)currentTime.length;
    [self.controlBar updateTimeLabel:currentTime];
}

-(void)updateImage:(UIImage*)image {
    if (image == nil) {
        image = [UIImage imageNamed:@"albumart_default"];
    }
    self.currentAlbumArtwork.image = image;
    
    if (curlView && self.onScreen) {
        [curlView drawImageOnFrontOfPage:[self imageWithImage:image scaledToSize:curlView.frame.size]];
    }
    
    [musicPlayer updateNowPlaying];
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

-(IBAction)editAllTableViews:(id)sender {
    if (editingTableViews == YES) {
        [self.editTableViews setImage:[UIImage imageNamed:@"dj"] forState:UIControlStateNormal];
        editingTableViews = NO;
        [self.songTableView setEditing:NO animated:YES];
        [self.peerTableView setEditing:NO animated:YES];
    }
    else {
        [self.editTableViews setImage:[UIImage imageNamed:@"dj_inuse"] forState:UIControlStateNormal];
        editingTableViews = YES;
        [self.songTableView setEditing:YES animated:YES];
        [self.peerTableView setEditing:YES animated:YES];
    }
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

#pragma mark MusicPickerDelegate

-(void)addPressed:(UIButton *)sender {
    [self presentViewController:musicPicker animated:YES completion:nil];
}

-(void)musicPicker:(MusicPickerViewController *)picker didPickItems:(NSArray *)items andMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    
    NSMutableArray *newSongs = [[NSMutableArray alloc] init];
    for (MPMediaItem *item in mediaItemCollection.items) {
        LocalSong *tempSong = [[LocalSong alloc] initWithItem:item andOutputASBD:*(musicPlayer.audioFormat) andPeer:[[QPSessionManager sessionManager] pid]];
        [newSongs addObject:tempSong];
    }
    for (id item in items) {
        if ([item isMemberOfClass:[SoundCloudSong class]]) {
            [((SoundCloudSong*)item) setOutputASBD:*(musicPlayer.audioFormat)];
            [newSongs addObject:item];
        }
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

#pragma mark TableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows = 0;
    if (tableView == self.songTableView) {
        numRows = musicPlayer.playlist.count;
    } else if (tableView == self.peerTableView) {
        numRows = sessionManager.connectedPeerArray.count;
    }
    return numRows < 1 ? 1 : numRows;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (tableView == self.songTableView) {
        cell = [self songTableView:tableView withIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else if (tableView == self.peerTableView) {
        cell = [self peerTableView:tableView withIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

-(UITableViewCell *)songTableView:(UITableView *)tableView withIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *finalCell = nil;
    
    if (musicPlayer.playlist.count < 1){
        PeerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PeerCell"];
        cell.backgroundColor = [UIColor clearColor];
        cell.mainLabel.text = @"No Songs";
        finalCell = cell;
    }
    else {
        SongTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SongCell"];
        cell.backgroundColor = [UIColor clearColor];
        Song *oneSong = [musicPlayer.playlist objectAtIndex:indexPath.row];
        cell.mainLabel.text = oneSong.title;
        cell.detailLabel.text = oneSong.artistName;
        finalCell = cell;
    }
    return finalCell;
}

-(UITableViewCell *)peerTableView:(UITableView *)tableView withIndexPath:(NSIndexPath *)indexPath {
    PeerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PeerCell"];
    cell.backgroundColor = [UIColor clearColor];
    
    if (sessionManager.connectedPeerArray.count < 1){
        cell.mainLabel.text = @"No Passengers";
    }
    else {
        MCPeerID *onePeer = [sessionManager.connectedPeerArray objectAtIndex:indexPath.row];
        cell.mainLabel.text = onePeer.displayName;
    }
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (sessionManager.currentRole == ClientConnection) {
        return NO;
    } else if (tableView == self.songTableView && musicPlayer.playlist.count > 0) {
        return YES;
    } else if (tableView == self.peerTableView && sessionManager.connectedPeerArray.count > 0) {
        return YES;
    }
    return NO;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.songTableView && editingStyle == UITableViewCellEditingStyleDelete) {
        [musicPlayer.playlist removeObjectAtIndex:[indexPath row]];
        if (musicPlayer.playlist.count > 0) {
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        } else {
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        }
        [sessionManager removeSongFromAllPeersAtIndex:[indexPath row]];
    } else if (tableView == self.peerTableView && editingStyle == UITableViewCellEditingStyleDelete) {
        //Remove peer from connectedpeerarray
        MCPeerID *bootedPeer = [sessionManager.connectedPeerArray objectAtIndex:[indexPath row]];
        [sessionManager.connectedPeerArray removeObjectAtIndex:[indexPath row]];
        //Send message to remove peer
        [sessionManager bootPeer:bootedPeer];
        
        if (sessionManager.connectedPeerArray.count > 0) {
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        } else {
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        }
    }
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    [musicPlayer switchSongFromIndex:sourceIndexPath.row to:destinationIndexPath.row];
    [sessionManager switchSongFrom:sourceIndexPath.row to:destinationIndexPath.row];
}

#pragma mark QPMusicPlayerPlaylistDelegate

-(void)songAdded:(Song *)song atIndex:(NSUInteger)ndx {
    [self.songTableView beginUpdates];
    if (musicPlayer.playlist.count == 1) {
        [self.songTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:ndx inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
    }
    [self.songTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:ndx inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
    [self.songTableView endUpdates];
}

-(void)songRemoved:(Song *)song atIndex:(NSInteger)ndx {
    [self.songTableView beginUpdates];
    [self.songTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:ndx inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
    if (musicPlayer.playlist.count == 0) {
        [self.songTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:ndx inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
    }
    [self.songTableView endUpdates];
}

-(void)songsRemovedAtIndexSet:(NSIndexSet *)ndxSet {
    [self.songTableView beginUpdates];
    [ndxSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self.songTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
    }];
    if (musicPlayer.playlist.count == 0) {
        [self.songTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
    }
    [self.songTableView endUpdates];
}

-(void)songMoved:(Song *)song fromIndex:(NSUInteger)ndx1 toIndex:(NSUInteger)ndx2 {
    [self.songTableView moveRowAtIndexPath:[NSIndexPath indexPathForRow:ndx1 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:ndx2 inSection:0]];
}

#pragma mark QPBrowsingManagerDelegate methods

-(void)foundPeer:(MCPeerID *)peerID {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[sessionManager.peerArray indexOfObject:peerID] + STATIC_NEARBY_TRAIN_CELLS inSection:0];
    [UIView animateWithDuration:0.18f animations:^(void) {
        [nearbyTrainsModal insertItemsAtIndexPaths:@[indexPath]];
    }];
}

-(void)lostPeer:(MCPeerID *)peerID atIndex:(NSUInteger)ndx {
    dispatch_async(dispatch_get_main_queue(), ^{
        [nearbyTrainsModal deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:ndx + STATIC_NEARBY_TRAIN_CELLS inSection:0]]];
    });
}

#pragma mark QPSessionDelegate methods

-(void)connectedToPeer:(MCPeerID *)peerID {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([peerID isEqual:sessionManager.server]) {
            NSLog(@"Successfully to server: %@", peerID.displayName);
            [self removeLoadingScreen];
        }
        
        NSUInteger ndx = [sessionManager.connectedPeerArray indexOfObject:peerID];
        [self.peerTableView beginUpdates];
        if (sessionManager.connectedPeerArray.count == 1) {
            [self.peerTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:ndx inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
        }
        [self.peerTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:ndx inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
        [self.peerTableView endUpdates];
    });
}

-(void)disconnectedFromPeer:(MCPeerID *)peerID atIndex:(NSUInteger)ndx {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.peerTableView beginUpdates];
        [self.peerTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:ndx inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
        if (sessionManager.connectedPeerArray.count == 0) {
            [self.peerTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:ndx inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
        }
        [self.peerTableView endUpdates];
    });
}

#pragma mark CollectionView for Nearby Trains

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return sessionManager.peerArray.count + STATIC_NEARBY_TRAIN_CELLS;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    AnimatedCollectionViewCell *cell = [nearbyTrainsModal dequeueReusableCellWithReuseIdentifier:@"AnimatedPeerCell" forIndexPath:indexPath];
    
    if (indexPath.row == 0) {
        cell.peerName.text = sessionManager.pid.displayName;
    } else {
        cell.peerName.text = [[sessionManager.peerArray objectAtIndex:indexPath.row - STATIC_NEARBY_TRAIN_CELLS] displayName];
    }
    
    if ([cell.peerName.text isEqualToString:sessionManager.server.displayName]) {
        cell.trainImage.image = [UIImage imageNamed:@"train"];
    } else {
        cell.trainImage.image = [UIImage imageNamed:@"train_inactive"];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        if (![sessionManager.server isEqual:sessionManager.pid]) {
            NSLog(@"restarting my session");
            [sessionManager restartSession];
        }
        [self finishBrowsingForOthers:NO];
    } else if ([sessionManager.server isEqual:[sessionManager.peerArray objectAtIndex:indexPath.row - STATIC_NEARBY_TRAIN_CELLS]]) {
        [self finishBrowsingForOthers:NO];
    } else {
        NSLog(@"connecting to another");
        [sessionManager connectToPeer:[sessionManager.peerArray objectAtIndex:indexPath.row - STATIC_NEARBY_TRAIN_CELLS]];
        [self finishBrowsingForOthers:YES];
    }
    
}

-(void)updateCurrentSong:(Song*)song {
    if (song == nil) {
        self.currentSongTitle.text = @" ";
        self.currentSongArtist.text = @" ";
    }
    else {
        if ([self.currentSongTitle.text isEqualToString:song.title] == NO ||
            [self.currentSongArtist.text isEqualToString:song.artistName] == NO) {
            [self hidePurchaseButton];
            
            [self searchiTunesForSong:song.title];
        }
        
        self.currentSongTitle.text = song.title;
        self.currentSongArtist.text = song.artistName;
        
        if ([song isMemberOfClass:[SoundCloudSong class]]) {
            self.streamingServiceIcon.hidden = NO;
        } else {
            self.streamingServiceIcon.hidden = YES;
        }
    }
}

-(void)searchiTunesForSong:(NSString*)song {
    NSString *searchTerm = [song stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSLog(@"iTunes Search API term: %@", [searchTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
    NSString *urlString = [NSString stringWithFormat:@"https://itunes.apple.com/search?entity=song&attribute=songTerm&limit=1&term=%@", searchTerm];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    __weak Song *weakSong = musicPlayer.currentSong;
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (response == nil) {
                                   NSLog(@"no returned data in searchiTunesForSong");
                                   return;
                               }
                               
                               if (!error) {
                                   NSError *parseError;
                                   id parse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&parseError];
                                   
                                   if (parseError == nil &&
                                       [parse objectForKey:@"results"] != nil &&
                                       [parse[@"results"] isKindOfClass:[NSArray class]] &&
                                       [parse[@"results"] count] > 0 &&
                                       [parse[@"results"][0] objectForKey:@"trackId"] != nil) {
                                       
                                       //NSLog(@"Presenting iTunes Search Results for %@", musicPlayer.currentSong.title);
                                       currentSongID = parse[@"results"][0][@"trackId"];
                                       shouldShowPurchaseButton = YES;
                                       [self showPurchaseButton];
                                   } else {
                                       [self searchiTunesForArtist:weakSong.artistName];
                                   }
                               }
                           }];
}

-(void)searchiTunesForArtist:(NSString*)artist {
    NSString *searchTerm = [artist stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSLog(@"iTunes Search API term: %@", [searchTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
    NSString *urlString = [NSString stringWithFormat:@"https://itunes.apple.com/search?entity=musicArtist&attribute=artistTerm&limit=1&term=%@", searchTerm];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (response == nil) {
                                   NSLog(@"no returned data in searchiTunesForArtist");
                                   return;
                               }
                               
                               if (!error) {
                                   NSError *parseError;
                                   id parse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&parseError];
                                   
                                   if (parseError == nil &&
                                       [parse objectForKey:@"results"] != nil &&
                                       [parse[@"results"] isKindOfClass:[NSArray class]] &&
                                       [parse[@"results"] count] > 0 &&
                                       [parse[@"results"][0] objectForKey:@"artistId"] != nil) {
                                       
                                       //NSLog(@"Presenting iTunes Search Results for %@", musicPlayer.currentSong.artistName);
                                       currentSongID = parse[@"results"][0][@"artistId"];
                                       shouldShowPurchaseButton = YES;
                                       [self showPurchaseButton];
                                   }
                               }
                           }];
}

#pragma mark Purchase Button

-(void)showPurchaseButton {
    if (self.onScreen == NO || curled == YES || shouldShowPurchaseButton == NO) {
        if (self.onScreen == YES) {
            [curlView drawImageOnFrontOfPage:[self imageWithImage:self.currentAlbumArtwork.image scaledToSize:curlView.frame.size]];
        }
        return;
    }
    
    NSLog(@"showpurchase button");
    CGRect r = self.currentAlbumArtwork.frame;
    curlView = [[XBCurlView alloc] initWithFrame:r horizontalResolution:250 verticalResolution:250 antialiasing:NO];
    
    curlView.opaque = NO; //Transparency on the next page (so that the view behind curlView will appear)
    curlView.pageOpaque = YES; //The page to be curled has no transparency
    
    [curlView curlView:self.currentAlbumArtwork cylinderPosition:CGPointMake(self.currentAlbumArtwork.frame.size.width * 3.0 / 4.0, self.currentAlbumArtwork.frame.size.height / 4.0) cylinderAngle:M_PI_4 cylinderRadius:5 animatedWithDuration:0.3];
    curled = YES;
    
    transparent = [[UIView alloc] initWithFrame:r];
    [self.view addSubview:transparent];
    [transparent addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openStore:)]];
}

-(void)hidePurchaseButton {
    shouldShowPurchaseButton = NO;
    
    if (self.onScreen == NO) {
        return;
    }
    
    [curlView uncurlAnimatedWithDuration:0.2];
    curlView = nil;
    curled = NO;
    
    [transparent removeFromSuperview];
    transparent = nil;
}

-(IBAction)openStore:(id)sender {
    NSDictionary *params = @{SKStoreProductParameterITunesItemIdentifier: currentSongID,
                             SKStoreProductParameterAffiliateToken: ITUNES_SEARCH_API_AFFILIATE_TOKEN,
                             SKStoreProductParameterCampaignToken: ITUNES_SEARCH_API_CAMPAIGN_TOKEN};
    
    storeController = [[SKStoreProductViewController alloc] init];
    storeController.delegate = self;
    
    [storeController loadProductWithParameters:params completionBlock:^(BOOL result, NSError *error) {
        if (error) {
            NSLog(@"Error in storekit: %@", error);
            [self dismissViewControllerAnimated:YES completion:^{
                NSLog(@"Dismissed store");
            }];
        }
    }];
    
    [self presentViewController:storeController animated:YES completion:nil];
}

-(void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
    storeController = nil;
}

#pragma mark KVO

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    __weak Song *weakSong = musicPlayer.currentSong;
    
    if ([keyPath isEqualToString:@"currentSong"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateCurrentSong:weakSong];
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
            [self hidePurchaseButton];
            [self updatePlayOrPauseImage];

            if (sessionManager.currentRole == ClientConnection) {
                self.editTableViews.hidden = YES;
                [self.controlBar switchControlPanel:ControlPanelPassenger];
            }
            else {
                self.editTableViews.hidden = NO;
                [self.controlBar switchControlPanel:ControlPanelConductor];
            }
            [self.songTableView reloadData];
            //[self.songTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        });
    } else if ([keyPath isEqualToString:@"currentSong.albumImage"]) {
        NSLog(@"Updating Image!!!!!!!!!!!!!");
        
        if ([weakSong isKindOfClass:[LocalSong class]] == NO && [weakSong.peer isEqual:sessionManager.pid]) {
            NSLog(@"Sending artwork to everyone");
            [sessionManager sendAlbumArtworkToEveryone:weakSong];
        }
         
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateImage:weakSong.albumImage];
        });
    }
}

@end
