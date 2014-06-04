//
//  SingleCellButton.m
//  SongTrain
//
//  Created by Quinton Petty on 1/22/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "SingleCellButton.h"

@implementation SingleCellButton

- (id)initWithFrame:(CGRect)frame
{
    frame = CGRectMake(frame.origin.x - 1, frame.origin.y, frame.size.width + 2, frame.size.height);
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColorFromRGBWithAlpha(0x464646, 0.67);
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        //self.contentEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
        [self.layer setBorderWidth:0.5f];
        [self.layer setBorderColor:UIColorFromRGBWithAlpha(0x252525, 0.7).CGColor];
    }
    return self;
}

@end
