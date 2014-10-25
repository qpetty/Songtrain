//
//  STSongTableViewCell.m
//  Songtrain
//
//  Created by Quinton Petty on 10/24/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "STSongTableViewCell.h"

@implementation STSongTableViewCell

-(instancetype)init {
    self = [super init];
    if (self) {
        [self setUpCell];
    }
    return self;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setUpCell {
    self.backgroundColor = UIColorFromRGBWithAlpha(0x4E5257, 0.3);
    self.textLabel.textColor = [UIColor whiteColor];
    self.userInteractionEnabled = YES;
    self.accessoryType = UITableViewCellAccessoryNone;
}

@end
