//
//  ControlPanel.m
//  SongTrain
//
//  Created by Quinton Petty on 2/9/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "ControlPanel.h"
#import "QPMusicPlayerController.h"

#define BUTTON_SIZE 40
#define LABEL_SIZE 100
#define LABEL_HEIGHT 30

@implementation ControlPanel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = UIColorFromRGBWithAlpha(0xc5d1de, 0.13);
        
        [self.layer setBorderWidth:0];
        
        //Create Add button
        
        CGRect location = CGRectMake((frame.size.width / 8.0) - (BUTTON_SIZE / 2.0),
                                     (frame.size.height / 2.0) - (BUTTON_SIZE / 2.0),
                                     BUTTON_SIZE,
                                     BUTTON_SIZE);
        addButton = [[UIButton alloc] initWithFrame:location];
        [self addSubview:addButton];
        addButton.tag = AddButton;
        [addButton setContentMode:UIViewContentModeScaleAspectFit];
        
        [addButton setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
        //[addButton setImage:[UIImage imageNamed:@"add_click"] forState:UIControlStateSelected];
        [addButton addTarget:self.delegate action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];

        // Create Skip Button

        location = CGRectMake((frame.size.width * (7.0 / 8.0)) - (BUTTON_SIZE / 2.0),
                              (frame.size.height / 2.0) - (BUTTON_SIZE / 2.0),
                              BUTTON_SIZE,
                              BUTTON_SIZE);
        skipButton = [[UIButton alloc] initWithFrame:location];
        skipButton.tag = SkipButton;
        [self addSubview:skipButton];
        [skipButton setContentMode:UIViewContentModeScaleAspectFit];

        [skipButton setImage:[UIImage imageNamed:@"skip"] forState:UIControlStateNormal];
        [skipButton setImage:[UIImage imageNamed:@"skip_disabled"] forState:UIControlStateSelected];
        [skipButton addTarget:self.delegate action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];

        //Create Progress Bar
        
        songProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [self addSubview:songProgress];
        songProgress.tintColor = UIColorFromRGB(0x7FA8D7);
        songProgress.frame = CGRectMake(0, -1, frame.size.width + 1, 11);
        songProgress.progress = 0.0;
        
        //Create Time Label
        
        location = CGRectMake((frame.size.width  / 4.0) - (LABEL_SIZE / 8.0),
                              (frame.size.height / 2.0) - (LABEL_HEIGHT / 2.0),
                              LABEL_SIZE,
                              LABEL_HEIGHT / 2.0);

        topLabel = [[UILabel alloc] initWithFrame:location];
        topLabel.text = @"0:00";
        topLabel.adjustsFontSizeToFitWidth = YES;
        topLabel.textColor = [UIColor whiteColor];
        topLabel.numberOfLines = 0;
        topLabel.textAlignment = NSTextAlignmentCenter;
        topLabel.font = [topLabel.font fontWithSize:14];
        [self addSubview:topLabel];
        
        location = CGRectMake((frame.size.width  / 4.0) - (LABEL_SIZE / 8.0),
                              (frame.size.height / 2.0),
                              LABEL_SIZE,
                              LABEL_HEIGHT / 2.0);
        
        bottomLabel = [[UILabel alloc] initWithFrame:location];
        bottomLabel.text = @"0:00";
        bottomLabel.adjustsFontSizeToFitWidth = YES;
        bottomLabel.textColor = UIColorFromRGB(0xC5D1DE);
        bottomLabel.numberOfLines = 0;
        bottomLabel.textAlignment = NSTextAlignmentCenter;
        bottomLabel.font = [bottomLabel.font fontWithSize:12];
        [self addSubview:bottomLabel];

        
        //Create Play Button
        location = CGRectMake((frame.size.width  * (5.0 / 8.0)) - (BUTTON_SIZE / 2.0),
                              (frame.size.height / 2.0) - (BUTTON_SIZE / 2.0),
                              BUTTON_SIZE,
                              BUTTON_SIZE);
        playButton = [[UIButton alloc] initWithFrame:location];
        playButton.tag = PlayButton;
        [playButton setContentMode:UIViewContentModeScaleAspectFit];
        [playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        [playButton addTarget:self.delegate action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:playButton];
    }
    return self;
}

- (void)setIsPlaying:(BOOL)isPlaying
{
    if (isPlaying) {
        [playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    }
    else {
        [playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    }
}

- (void)setSongDuration:(NSRange)songDuration
{
    songProgress.progress = (float)songDuration.location / (float)songDuration.length;
    
    int totalMinutes = 0, currentMinutes = 0;
    
    while (songDuration.length >= 60) {
        totalMinutes++;
        songDuration.length -= 60;
    }
    while (songDuration.location >= 60) {
        currentMinutes++;
        songDuration.location -= 60;
    }
    topLabel.text = [NSString stringWithFormat:@"%d:%.2lu", currentMinutes, songDuration.location];
    bottomLabel.text = [NSString stringWithFormat:@"%d:%.2lu", totalMinutes, songDuration.length];
    //timeLabel.text = [NSString stringWithFormat:@"%d:%.2lu\n%d:%.2lu", currentMinutes, songDuration.location, totalMinutes, songDuration.length];
}

@end
