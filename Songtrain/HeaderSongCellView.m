//
//  HeaderSongCellView.m
//  Songtrain
//
//  Created by Quinton Petty on 10/4/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "HeaderSongCellView.h"

@implementation HeaderSongCellView

-(void)awakeFromNib {
    [self.layer setBorderWidth:0.5f];
    [self.layer setBorderColor:[UIColor blackColor].CGColor];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
