//
//  CurrentSongView.m
//  SongTrain
//
//  Created by Quinton Petty on 1/21/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "CurrentSongView.h"

#define SPACE_BETWEEN_BUTTONS 8
#define BUTTON_SIZE 30

@implementation CurrentSongView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
        self.userInteractionEnabled = YES;
        
        self.tintColor = UIColorFromRGB(0x797979);
        self.backgroundColor = UIColorFromRGB(0x464646);
        
        //Song Title
        songTitle = [[UILabel alloc] init];
        [self addSubview:songTitle];
        songTitle.textColor = [UIColor whiteColor];
        [songTitle setFont:[UIFont systemFontOfSize:26]];
        
        songTitle.frame = CGRectMake(15,
                                     songTitle.superview.frame.size.height / 3 ,
                                     songTitle.superview.frame.size.width * 0.6,
                                     songTitle.superview.frame.size.height / 4);
        
        //Song Artist
        songArtist = [[UILabel alloc] init];
        [self addSubview:songArtist];
        songArtist.textColor = [UIColor whiteColor];
        [songArtist setFont:[UIFont systemFontOfSize:16]];
        
        songArtist.frame = CGRectMake(songTitle.frame.origin.x,
                                      songTitle.frame.origin.y + songTitle.frame.size.height,
                                      songTitle.frame.size.width,
                                      songTitle.frame.size.height * 0.6);
        
        //Song Album Artwork Setup
        self.contentMode = UIViewContentModeScaleAspectFill;
        self.clipsToBounds = YES;
        
        //Progress View
        songProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [self addSubview:songProgress];
        songProgress.frame = CGRectMake(songArtist.frame.origin.x,
                                        songArtist.frame.origin.y + songArtist.frame.size.height * 1.5,
                                        songArtist.superview.frame.size.width - 2 * songArtist.frame.origin.x,
                                        30);
        
        [self setProgressTimer];
        
        //Add buttons
        //Info Button
        infoButton = [[UIButton alloc] initWithFrame:CGRectMake(songProgress.frame.origin.x + songProgress.frame.size.width - BUTTON_SIZE,
                                                                songTitle.frame.origin.y + songTitle.frame.size.height * 0.4,
                                                                BUTTON_SIZE,
                                                                BUTTON_SIZE)];
        infoButton.tag = InfoButton;
        [infoButton setImage:[UIImage imageNamed:@"infoButton"] forState:UIControlStateNormal];
        [infoButton addTarget:self.delegate action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:infoButton];
        
    }
    return self;
}

- (id)initWithPlayer:(MPMusicPlayerController*)player andFrame:(CGRect)frame
{
    self = [self initWithFrame:frame];
    if (self) {
        musicPlayer = player;
        currentSong = [musicPlayer nowPlayingItem];
        self.showArtwork = YES;
        
        //Get Song info
        [self updateSongInfo:currentSong];
        
        //Subscribe to changes of the musicPlayer to update song info
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(nowPlayingItemChanged:) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:musicPlayer];
        [notificationCenter addObserver:self selector:@selector(playbackStateChanged:) name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:musicPlayer];
        [musicPlayer beginGeneratingPlaybackNotifications];
    }
    
    return self;
}

- (void)updateSongInfo:(MPMediaItem*)song
{
    currentSong = song;
    songTitle.text = [currentSong valueForProperty:MPMediaItemPropertyTitle];
    songArtist.text = [currentSong valueForProperty:MPMediaItemPropertyArtist];
    if (self.showArtwork)
        self.image = [self getAlbumImage];
    else
        self.image = nil;
}

- (void)updateProgressBar
{
    songProgress.progress = musicPlayer.currentPlaybackTime / [[currentSong valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
}

- (void)setIsShowArtwork:(BOOL)show
{
    if (show)
        self.image = [self getAlbumImage];
    else
        self.image = nil;
    _showArtwork = show;
}

- (void)setIsShowInfoButton:(BOOL)show
{
    if (show)
        infoButton.hidden = NO;
    else
        infoButton.hidden = YES;
    _showInfoButton = show;
}


- (void)setProgressTimer{
    progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateProgressBar) userInfo:nil repeats:YES];
}

- (void)nowPlayingItemChanged:(id)sender
{
    [self updateSongInfo:[musicPlayer nowPlayingItem]];
    [self updateProgressBar];
}

- (void)playbackStateChanged:(id)sender
{
    
    MPMusicPlaybackState playbackState = [musicPlayer playbackState];
    
    
    if (playbackState == MPMusicPlaybackStatePlaying){
        if (!progressTimer) {
            [self setProgressTimer];
        }
    }
    else{
        [progressTimer invalidate];
        progressTimer = nil;
    }
}

- (UIImage*)getAlbumImage
{
    UIImage *image;
    MPMediaItemArtwork *albumItem = [currentSong valueForProperty:MPMediaItemPropertyArtwork];
    if (albumItem)
        image = [albumItem imageWithSize:CGSizeMake(albumItem.bounds.size.width, albumItem.bounds.size.height)];
    else
        NSLog(@"No Current Image\n");
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, 0, image.size.width, image.size.height / 2));
    
    return [UIImage imageWithCGImage:imageRef];
}



@end
