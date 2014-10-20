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

#define ITUNES_SEARCH_API_AFFILIATE_TOKEN @""
#define ITUNES_SEARCH_API_CAMPAIGN_TOKEN @""

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
    SKStoreProductViewController *storeController;
    NSString *currentSongID;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.songTableView registerNib:[UINib nibWithNibName:@"SongTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"SongCell"];
    [self.songTableView registerNib:[UINib nibWithNibName:@"PeerTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"PeerCell"];
    [self.peerTableView registerNib:[UINib nibWithNibName:@"PeerTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"PeerCell"];

    UICollectionViewFlowLayout *layout = [[AnimatedCollectionViewFlowLayout alloc] init];
    nearbyTrainsModal = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    [nearbyTrainsModal registerNib:[UINib nibWithNibName:@"AnimatedCollectionViewCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"AnimatedPeerCell"];
    nearbyTrainsModal.delegate = self;
    nearbyTrainsModal.dataSource = self;
    nearbyTrainsModal.backgroundColor = UIColorFromRGBWithAlpha(0x111111, 0.4);
    nearbyTrainsModal.backgroundView = [[UIView alloc] initWithFrame:nearbyTrainsModal.frame];
    UITapGestureRecognizer *tapAnywhere = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(outsideOfCellTap:)];
    nearbyTrainsModal.backgroundView.gestureRecognizers = @[tapAnywhere];

    backgroundImage = [[UIImageView alloc] initWithFrame:self.view.frame];
    backgroundOverlay = [[UIImageView alloc] initWithFrame:self.view.frame];
    nearbyTrainBackground = [[UIView alloc] initWithFrame:self.view.frame];
    nearbyTrainBackground.backgroundColor = UIColorFromRGBWithAlpha(0x111111, .8);
    loadingIcon = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [nearbyTrainBackground addSubview:loadingIcon];
    
    musicPlayer = [QPMusicPlayerController sharedMusicPlayer];
    [musicPlayer resetToServer];
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
    
    //Hide the purchase button initally and then only show once search results are loaded
    self.purchaseButton.hidden = YES;
}


- (void)outsideOfCellTap:(id)sender {
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
    [backgroundOverlay setFrame:self.view.frame];
    backgroundOverlay.backgroundColor = UIColorFromRGBWithAlpha(0x111111, .8);
    
    [self.view addSubview:backgroundOverlay];
    [self.view sendSubviewToBack:backgroundOverlay];
    
    [backgroundImage setFrame:CGRectMake(self.view.frame.origin.x - 10, self.view.frame.origin.y - 10, self.view.frame.size.width + 20, self.view.frame.size.height + 20)];
    backgroundImage.image = [self blurImage: [self cropAlbumImage:self.currentAlbumArtwork.image withScreenRect:self.view.frame]];

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
    [sessionManager addObserver:self forKeyPath:@"connectedPeerArray" options:NSKeyValueObservingOptionNew context:nil];
    [musicPlayer addObserver:self forKeyPath:@"currentSong" options:NSKeyValueObservingOptionNew context:nil];
    [musicPlayer addObserver:self forKeyPath:@"currentSongTime" options:NSKeyValueObservingOptionNew context:nil];
    [musicPlayer addObserver:self forKeyPath:@"currentSong.albumImage" options:NSKeyValueObservingOptionNew context:nil];
    [self updatePlayOrPauseImage];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateCurrentSong];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [sessionManager removeObserver:self forKeyPath:@"server"];
    [sessionManager removeObserver:self forKeyPath:@"connectedPeerArray"];
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
    
    [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:3 options:UIViewAnimationOptionTransitionNone animations:^{
        [nearbyTrainsModal setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height)];

    } completion:^(BOOL finished) {
        [nearbyTrainsModal reloadItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]]];
        [sessionManager startBrowsingForTrains];
    }];
}

-(void)finishBrowsingForOthers:(BOOL)somethingSelected
{
    [sessionManager stopBrowsingForTrains];
    [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:3 options:UIViewAnimationOptionTransitionNone animations:^{
        [nearbyTrainsModal setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    } completion:^(BOOL finished) {
    }];
    
    
    if (somethingSelected == NO) {
        [self removeLoadingScreen];
    } else {
        loadingIcon.center = nearbyTrainBackground.center;
        [loadingIcon startAnimating];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    [nearbyTrainsModal removeFromSuperview];
    [nearbyTrainsModal reloadData];
}

-(void)removeLoadingScreen {
    [loadingIcon stopAnimating];
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
    backgroundImage.image = [self blurImage:self.currentAlbumArtwork.image];
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
        LocalSong *tempSong = [[LocalSong alloc] initWithOutputASBD:*(musicPlayer.audioFormat) andItem:item];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[sessionManager.peerArray indexOfObject:peerID] + 1 inSection:0];
        [nearbyTrainsModal insertItemsAtIndexPaths:@[indexPath]];
    });
}

-(void)lostPeer:(MCPeerID *)peerID atIndex:(NSUInteger)ndx {
    dispatch_async(dispatch_get_main_queue(), ^{
        [nearbyTrainsModal deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:ndx + 1 inSection:0]]];
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
    return sessionManager.peerArray.count + 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    AnimatedCollectionViewCell *cell = [nearbyTrainsModal dequeueReusableCellWithReuseIdentifier:@"AnimatedPeerCell" forIndexPath:indexPath];
    
    if (indexPath.row == 0) {
        cell.peerName.text = sessionManager.pid.displayName;
    } else {
        cell.peerName.text = [[sessionManager.peerArray objectAtIndex:indexPath.row - 1] displayName];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        if (![sessionManager.server.displayName isEqualToString:sessionManager.pid.displayName]) {
            [sessionManager restartSession];
        }
        [self finishBrowsingForOthers:NO];
    } else {
        [sessionManager connectToPeer:[sessionManager.peerArray objectAtIndex:indexPath.row - 1]];
        [self finishBrowsingForOthers:YES];
    }
}

-(void)updateCurrentSong {
    if (musicPlayer.currentSong == nil) {
        self.currentSongTitle.text = @" ";
        self.currentSongArtist.text = @" ";
        [self updateImage:nil];
    }
    else {
        if ([self.currentSongTitle.text isEqualToString:musicPlayer.currentSong.title] == NO ||
            [self.currentSongArtist.text isEqualToString:musicPlayer.currentSong.artistName] == NO) {
            self.purchaseButton.hidden = YES;
            NSString *searchTerm = [musicPlayer.currentSong.artistName stringByReplacingOccurrencesOfString:@" " withString:@"+"];
            NSLog(@"iTunes Search API term: %@", [searchTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
            NSString *urlString = [NSString stringWithFormat:@"https://itunes.apple.com/search?entity=allArtist&attribute=allArtistTerm&limit=1&term=%@", searchTerm];
            NSURL *url = [NSURL URLWithString:urlString];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [NSURLConnection sendAsynchronousRequest:request
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       if (!error) {
                                           NSError *parseError;
                                           id parse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&parseError];
                                           //NSLog(@"%@", parse[@"results"][0]);
   
                                           if (parseError == nil &&
                                               [parse objectForKey:@"results"] != nil &&
                                               [parse[@"results"] isMemberOfClass:[NSArray class]] &&
                                               [parse[@"results"][0] objectForKey:@"artistId"] != nil) {
                                               currentSongID = parse[@"results"][0][@"artistId"];
                                               self.purchaseButton.hidden = NO;
                                           }
                                       }
                                   }];
        }
        
        self.currentSongTitle.text = musicPlayer.currentSong.title;
        self.currentSongArtist.text = musicPlayer.currentSong.artistName;
        [self updateImage:musicPlayer.currentSong.albumImage];
    }
}

#pragma mark Purchase Button

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
    if ([keyPath isEqualToString:@"currentSong"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateCurrentSong];
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

            if (sessionManager.currentRole == ClientConnection) {
                self.editTableViews.hidden = YES;
                [self.controlBar switchControlPanel:ControlPanelPassenger];
            }
            else {
                self.editTableViews.hidden = NO;
                [self.controlBar switchControlPanel:ControlPanelConductor];
            }
            [self.songTableView reloadData];
        });
    } else if ([keyPath isEqualToString:@"currentSong.albumImage"]) {
        [self updateImage:musicPlayer.currentSong.albumImage];
    }
}

@end
