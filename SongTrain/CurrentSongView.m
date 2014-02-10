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
        
        //Add buttons
        //Info Button
        
        //TODO: Replace 200 with some better values
        infoButton = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width * (9.0 / 10.0) - BUTTON_SIZE,
                                                                songTitle.frame.origin.y + songTitle.frame.size.height * 0.4,
                                                                BUTTON_SIZE,
                                                                BUTTON_SIZE)];
        infoButton.tag = InfoButton;
        [infoButton setImage:[UIImage imageNamed:@"infoButton"] forState:UIControlStateNormal];
        [infoButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:infoButton];
        
        self.showArtwork = YES;
        
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

- (void)buttonPressed:(UIButton*)button
{
    [self.delegate buttonPressed:button withSong:currentSong];
}

- (void)updateSongInfo:(Song*)song
{
    currentSong = song;
    songTitle.text = currentSong.title;
    songArtist.text = currentSong.artistName;
    if (self.showArtwork)
        self.image = [self cropAlbumImage:currentSong.albumImage];
    else
        self.image = nil;
}

- (void)setIsShowArtwork:(BOOL)show
{
    if (show)
        self.image = [self cropAlbumImage:currentSong.albumImage];
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

- (UIImage*)cropAlbumImage:(UIImage*)image
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, 0, image.size.width, image.size.height / 2));
    
    return [UIImage imageWithCGImage:imageRef];
}



@end
