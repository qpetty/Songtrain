//
//  ControlPanel.m
//  SongTrain
//
//  Created by Quinton Petty on 2/9/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "ControlPanel.h"

#define BUTTON_SIZE 30
#define LABEL_SIZE 100

@implementation ControlPanel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        
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
        [addButton setImage:[UIImage imageNamed:@"add_click"] forState:UIControlStateSelected];
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
        [skipButton setImage:[UIImage imageNamed:@"skip_click"] forState:UIControlStateSelected];
        [skipButton addTarget:self.delegate action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];

        //Create Progress Bar
        
        songProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [self addSubview:songProgress];
        songProgress.tintColor = UIColorFromRGB(0x7FA8D7);
        songProgress.frame = CGRectMake(0, 0, frame.size.width, 10);
        songProgress.progress = 0.0;
        
        //Create Time Label
        
        location = CGRectMake((frame.size.width / 2.0) - (LABEL_SIZE / 2.0),
                              (frame.size.height / 2.0) - (BUTTON_SIZE / 2.0),
                              LABEL_SIZE,
                              BUTTON_SIZE);
        timeLabel = [[UILabel alloc] initWithFrame:location];
        timeLabel.text = @"0:00-0:00";
        timeLabel.textColor = [UIColor whiteColor];
        timeLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:timeLabel];
    }
    return self;
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
    timeLabel.text = [NSString stringWithFormat:@"%d:%.2lu - %d:%.2lu", currentMinutes, songDuration.location, totalMinutes, songDuration.length];
}

@end
