//
//  GrayTableView.m
//  SongTrain
//
//  Created by Quinton Petty on 1/22/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "GrayTableView.h"

@implementation GrayTableView

- (id)initWithFrame:(CGRect)frame
{
    frame = CGRectMake(frame.origin.x - 1, frame.origin.y, frame.size.width + 2, frame.size.height);
    maxHeight = frame.size.height;
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColorFromRGBWithAlpha(0x464646, 0.67);
        [self.layer setBorderWidth:0.5f];
        [self.layer setBorderColor:UIColorFromRGBWithAlpha(0x252525, 0.7).CGColor];
        self.separatorColor = UIColorFromRGB(0x252525);
        self.scrollEnabled = NO;

    }
    return self;
}

-(void)reloadData
{
    [super reloadData];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDuration:0.5];
    
    CGRect newFrame = self.frame;
    double newHeight = 0;
    
    for (int i = 0; i < [self numberOfSections]; i++) {
        newHeight += self.rowHeight * [self numberOfRowsInSection:i];
    }
    
    if (newHeight > maxHeight){
        newHeight = maxHeight;
        self.scrollEnabled = YES;
    }
    else
        self.scrollEnabled = NO;
    
    newFrame.size.height = newHeight;
    self.frame = newFrame;
    
    [UIView commitAnimations];
}


@end
