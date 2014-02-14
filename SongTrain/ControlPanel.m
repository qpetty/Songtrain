//
//  ControlPanel.m
//  SongTrain
//
//  Created by Quinton Petty on 2/9/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "ControlPanel.h"

#define BUTTON_SIZE 30

@implementation ControlPanel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        
        //Create Add button
        
        CGRect location = CGRectMake(frame.size.width / 6,
                                     frame.size.height / 5,
                                     BUTTON_SIZE,
                                     BUTTON_SIZE);
        addButton = [[UIButton alloc] initWithFrame:location];
        [self addSubview:addButton];
        [addButton setContentMode:UIViewContentModeScaleAspectFit];
        
        [addButton setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
        [addButton setImage:[UIImage imageNamed:@"add_click"] forState:UIControlStateSelected];
        //[addButton addTarget:self.delegate action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];

        // Create Skip Button

        location = CGRectMake(frame.size.width - location.origin.x - BUTTON_SIZE, location.origin.y, BUTTON_SIZE, BUTTON_SIZE);
        skipButton = [[UIButton alloc] initWithFrame:location];
        [self addSubview:skipButton];
        [skipButton setContentMode:UIViewContentModeScaleAspectFit];

        [skipButton setImage:[UIImage imageNamed:@"skip"] forState:UIControlStateNormal];
        [skipButton setImage:[UIImage imageNamed:@"skip_click"] forState:UIControlStateSelected];
        //[skipButton addTarget:self.delegate action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];

        //Create Progress Bar
        
        songProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [self addSubview:songProgress];
        songProgress.frame = CGRectMake(0, 0, frame.size.width, 10);
        songProgress.progress = 0.5;
    }
    return self;
}

@end
