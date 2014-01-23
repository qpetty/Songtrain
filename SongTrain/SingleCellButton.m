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
        self.backgroundColor = UIColorFromRGB(0x464646);
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        self.contentEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
        [self.layer setBorderWidth:1.0f];
        [self.layer setBorderColor:UIColorFromRGB(0x707070).CGColor];
    }
    return self;
}

@end
