//
//  CurrentSongView.m
//  SongTrain
//
//  Created by Quinton Petty on 1/21/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "CurrentSongView.h"

#define SPACE_BETWEEN_BUTTONS 8

@implementation CurrentSongView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
        self.userInteractionEnabled = YES;
        
        self.tintColor = UIColorFromRGB(0x797979);
        
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
        songProgress.progress = 0.5;
        
        //Add buttons
        //Info Button
        infoButton = [[UIButton alloc] initWithFrame:CGRectMake(songTitle.frame.origin.x + songTitle.frame.size.width,
                                                                songTitle.frame.origin.y + songTitle.frame.size.height * 0.4,
                                                                30,
                                                                30)];
        infoButton.tag = InfoButton;
        [infoButton setImage:[UIImage imageNamed:@"infoButton"] forState:UIControlStateNormal];
        [infoButton addTarget:self.delegate action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:infoButton];
        
        //Favorite Button
        favoriteButton = [[UIButton alloc] initWithFrame:CGRectMake(infoButton.frame.origin.x + infoButton.frame.size.width + SPACE_BETWEEN_BUTTONS,
                                                                    infoButton.frame.origin.y,
                                                                    infoButton.frame.size.width,
                                                                    infoButton.frame.size.height)];
        favoriteButton.tag = FavoriteButton;
        [favoriteButton setImage:[UIImage imageNamed:@"favoriteButton"] forState:UIControlStateNormal];
        [favoriteButton addTarget:self.delegate action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:favoriteButton];
        
        //Mute Button
        muteButton = [[UIButton alloc] initWithFrame:CGRectMake(favoriteButton.frame.origin.x + favoriteButton.frame.size.width + SPACE_BETWEEN_BUTTONS,
                                                                favoriteButton.frame.origin.y,
                                                                favoriteButton.frame.size.width,
                                                                favoriteButton.frame.size.height)];
        muteButton.tag = MuteButton;
        [muteButton setImage:[UIImage imageNamed:@"muteButton-white"] forState:UIControlStateNormal];
        [muteButton addTarget:self.delegate action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:muteButton];
    }
    return self;
}

- (id)initWithSong:(MPMediaItem*)song andFrame:(CGRect)frame
{
    self = [self initWithFrame:frame];
    if (self) {
        currentSong = song;
    
        //Get Song info
        [self updateSongInfo:song];
    }
    
    return self;
}

- (void)updateSongInfo:(MPMediaItem*)song
{
    currentSong = song;
    songTitle.text = [currentSong valueForProperty:MPMediaItemPropertyTitle];
    songArtist.text = [currentSong valueForProperty:MPMediaItemPropertyArtist];
    self.image = [self getAlbumImage];
}

- (void)updateProgressBar:(NSTimeInterval)time
{
    songProgress.progress = time / [[currentSong valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
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
