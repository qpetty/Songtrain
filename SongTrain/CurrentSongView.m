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
        self.userInteractionEnabled = YES;
        
        self.tintColor = UIColorFromRGB(0x797979);
        self.backgroundColor = UIColorFromRGB(0x464646);
        
        //Blur Filter
        blurFilter = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        blurFilter.backgroundColor = UIColorFromRGBWithAlpha(0x464646, 0.67);
        [self addSubview:blurFilter];
        
        //Add Tiny Album Cover
        self.tinyAlbumView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 16, self.frame.size.height - 16 * 2, self.frame.size.height - 16 * 2)];
        [self addSubview:self.tinyAlbumView];
        
        //Song Title
        CGRect tempFrame = CGRectMake(self.tinyAlbumView.frame.size.width + self.tinyAlbumView.frame.origin.x + 5,
                                     self.tinyAlbumView.frame.origin.y + self.tinyAlbumView.frame.size.height - 40,
                                     self.frame.size.width * 0.6,
                                     self.frame.size.height / 4);
        
        songTitle = [[MarqueeLabel alloc] initWithFrame:tempFrame rate:75.0 andFadeLength:10.0f];
        ((MarqueeLabel*)songTitle).marqueeType = MLContinuous;
        ((MarqueeLabel*)songTitle).continuousMarqueeExtraBuffer = 25.0f;
        ((MarqueeLabel*)songTitle).animationDelay = 5.0f;
        
        [self addSubview:songTitle];
        songTitle.textColor = [UIColor whiteColor];
        [songTitle setFont:[UIFont fontWithName:@"HelveticaNeue" size:17.0f]];
        
        //Song Artist
        songArtist = [[UILabel alloc] init];
        [self addSubview:songArtist];
        songArtist.textColor = [UIColor whiteColor];
        [songArtist setFont:[UIFont fontWithName:@"HelveticaNeue" size:14.0f]];
        
        songArtist.frame = CGRectMake(songTitle.frame.origin.x + 10,
                                      songTitle.frame.origin.y + songTitle.frame.size.height,
                                      songTitle.frame.size.width,
                                      songTitle.frame.size.height * 0.6);
        
        //Song Album Artwork Setup
        self.contentMode = UIViewContentModeScaleAspectFill;
        self.clipsToBounds = YES;
        self.showArtwork = YES;
        
        //Borders
        self.layer.borderWidth = 0.5f;
    }
    return self;
}

- (id)initWithSong:(Song*)song andFrame:(CGRect)frame
{
    self = [self initWithFrame:frame];
    if (self) {
        [self updateSongInfo:song];
    }
    
    return self;
}

- (void)updateSongInfo:(Song*)song
{
    currentSong = song;
    songTitle.text = currentSong.title;
    songArtist.text = currentSong.artistName;
    [self setIsShowArtwork:self.showArtwork];
}

- (void)setIsShowArtwork:(BOOL)show
{
    if (show) {
        self.image = [self cropAlbumImage:currentSong.albumImage];
        self.tinyAlbumView.image = currentSong.albumImage;
    } else {
        self.image = nil;
        self.tinyAlbumView.image = nil;
    }
    _showArtwork = show;
}

- (UIImage*)cropAlbumImage:(UIImage*)image
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, 0, image.size.width, image.size.height / 2));
    
    return [UIImage imageWithCGImage:imageRef];
}

@end
