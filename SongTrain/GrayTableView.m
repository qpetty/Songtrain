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
        self.backgroundColor = UIColorFromRGB(0x464646);
        [self.layer setBorderWidth:1.0f];
        [self.layer setBorderColor:UIColorFromRGB(0x707070).CGColor];
        self.separatorColor = UIColorFromRGB(0x363636);
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
