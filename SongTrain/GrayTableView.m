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
        self.backgroundColor = [UIColor clearColor];
        [self.layer setBorderWidth:0.5f];
        [self.layer setBorderColor:UIColorFromRGBWithAlpha(0x252525, 0.7).CGColor];
        self.separatorColor = UIColorFromRGB(0x252525);
        self.scrollEnabled = NO;
        
        self.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    return self;
}

-(void)reloadData
{
    [super reloadData];
    [self adjustHeight];
}

- (void)adjustHeight
{
    double newHeight = 0;
    
    for (int i = 0; i < [self numberOfSections]; i++) {
        newHeight += self.rowHeight * [self numberOfRowsInSection:i];
    }
    
    if (newHeight > maxHeight)
        self.scrollEnabled = YES;
    else
        self.scrollEnabled = NO;
}

@end
