//
//  ServerControlPanel.m
//  SongTrain
//
//  Created by Brandon on 6/6/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "ServerControlPanel.h"

@implementation ServerControlPanel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
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
    [super setSongDuration:songDuration];
    topLabel.text = [NSString stringWithFormat:@"%d:%.2lu", currentMinutes, (unsigned long)currentSeconds];
    bottomLabel.text = [NSString stringWithFormat:@"%d:%.2lu", totalMinutes, (unsigned long)totalSeconds];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
