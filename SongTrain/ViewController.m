//
//  ViewController.m
//  Songtrain
//
//  Created by Quinton Petty on 9/18/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "ViewController.h"

#import "QPMusicPlayerController.h"
#import "SongTableViewCell.h"

@interface ViewController ()

@end

@implementation ViewController {
    QPMusicPlayerController *musicPlayer;
    MusicPickerViewController *musicPicker;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.mainTableView registerNib:[UINib nibWithNibName:@"SongTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"SongCell"];
    
    musicPlayer = [QPMusicPlayerController sharedMusicPlayer];
    [musicPlayer resetToServer];
    
    musicPicker = [[MusicPickerViewController alloc] init];
    musicPicker.delegate = self;

    self.currentSongTitle.rate = 75.0;
    self.currentSongTitle.fadeLength = 10.0;
    self.currentSongTitle.marqueeType = MLContinuous;
    self.currentSongTitle.continuousMarqueeExtraBuffer = 25.0;
    self.currentSongTitle.animationDelay = 5.0;
}

-(void)viewDidLayoutSubviews {
    
    //Adjusts the label's positioning due to the MarqueeLabel fadeLength
    self.currentSongTitle.frame = CGRectMake(self.currentSongTitle.frame.origin.x - 10.0,
                                             self.currentSongTitle.frame.origin.y,
                                             self.currentSongTitle.frame.size.width,
                                             self.currentSongTitle.frame.size.height);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [musicPlayer addObserver:self forKeyPath:@"playlist" options:NSKeyValueObservingOptionNew context:nil];
    [musicPlayer addObserver:self forKeyPath:@"currentSong" options:NSKeyValueObservingOptionNew context:nil];
    [musicPlayer addObserver:self forKeyPath:@"currentSongTime" options:NSKeyValueObservingOptionNew context:nil];
    [self updatePlayOrPauseImage];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [musicPlayer removeObserver:self forKeyPath:@"playlist"];
    [musicPlayer removeObserver:self forKeyPath:@"currentSong"];
    [musicPlayer removeObserver:self forKeyPath:@"currentSongTime"];
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
        [musicPlayer addSongsToPlaylist:newSongs];
    }];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark TableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return musicPlayer.playlist.count < 1 ? 1 : musicPlayer.playlist.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SongTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SongCell"];
    if (!cell) {
        NSLog(@"Something went wrong because we dont have a tableviewcell");
    }
    
    if (musicPlayer.playlist.count < 1){
        cell.mainLabel.text = @"No Songs";
        cell.detailLabel.text = @"";
    }
    else {
        Song *oneSong = [musicPlayer.playlist objectAtIndex:indexPath.row];
        cell.mainLabel.text = oneSong.title;
        cell.detailLabel.text = oneSong.artistName;
    }
    
    return cell;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"playlist"]) {
        [self.mainTableView reloadData];
    }
    else if ([keyPath isEqualToString:@"currentSong"]) {
        self.currentSongTitle.text = musicPlayer.currentSong.title;
        self.currentSongArtist.text = musicPlayer.currentSong.artistName;
        self.currentAlbumArtwork.image = musicPlayer.currentSong.albumImage == nil ? [UIImage imageNamed:@"albumart_default"] : musicPlayer.currentSong.albumImage;
    }
    else if ([keyPath isEqualToString:@"currentSongTime"]) {
        [self updateCurrentTime];
    }
}

@end
