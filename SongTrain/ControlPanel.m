//
//  ControlPanel.m
//  SongTrain
//
//  Created by Quinton Petty on 2/9/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "ControlPanel.h"
#import "QPMusicPlayerController.h"



@implementation ControlPanel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = UIColorFromRGBWithAlpha(0xc5d1de, 0.13);
        
        [self.layer setBorderWidth:0];
        
        //Create Add button
        
        location = CGRectMake((frame.size.width / 8.0) - (BUTTON_SIZE / 2.0),
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
        
        //Create Progress Bar
        
        songProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [self addSubview:songProgress];
        songProgress.tintColor = UIColorFromRGB(0x7FA8D7);
        songProgress.frame = CGRectMake(0, -1, frame.size.width + 1, 11);
        songProgress.progress = 0.0;

    }
    return self;
}

- (void)setSongDuration:(NSRange)songDuration
{
    songProgress.progress = (float)songDuration.location / (float)songDuration.length;
    
    totalMinutes = 0;
    currentMinutes = 0;
    
    while (songDuration.length >= 60) {
        totalMinutes++;
        songDuration.length -= 60;
    }
    while (songDuration.location >= 60) {
        currentMinutes++;
        songDuration.location -= 60;
    }
}

@end
