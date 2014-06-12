//
//  ClientControlPanel.m
//  SongTrain
//
//  Created by Brandon on 6/6/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "ClientControlPanel.h"

@implementation ClientControlPanel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        location = CGRectMake((frame.size.width * 3.0/4.0) - (LABEL_WIDTH/2.0),  (frame.size.height/2.0) - (LABEL_HEIGHT/2.0), LABEL_WIDTH, LABEL_HEIGHT);
        
        timeLabel = [[UILabel alloc] initWithFrame:location];
        timeLabel.adjustsFontSizeToFitWidth = YES;
        timeLabel.textColor = [UIColor whiteColor];
        timeLabel.textAlignment = NSTextAlignmentCenter;
        timeLabel.font = [timeLabel.font fontWithSize:14];
        timeLabel.text = @"0:00 0:00";
        [self addSubview:timeLabel];
    }
    return self;
}

- (void)setIsPlaying:(BOOL)isPlaying
{
    
}

- (void)setSongDuration:(NSRange)songDuration
{
    [super setSongDuration:songDuration];
    timeLabel.text = [NSString stringWithFormat:@"%d:%.2lu %d:%.2lu", currentMinutes, (unsigned long)currentSeconds, totalMinutes, (unsigned long)totalSeconds];
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
