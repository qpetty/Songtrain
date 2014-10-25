//
//  STMusicPickerTableView.m
//  Songtrain
//
//  Created by Quinton Petty on 10/24/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "STMusicPickerTableView.h"

@implementation STMusicPickerTableView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = UIColorFromRGBWithAlpha(0x222222, 1.0);
        self.sectionIndexBackgroundColor = [UIColor clearColor];
        self.sectionIndexColor = UIColorFromRGBWithAlpha(0xFFFFFF, 1.0);
        
        self.separatorColor = UIColorFromRGBWithAlpha(0x222222, 1.0);
        
        self.layer.borderWidth = 0.5f;
        self.layer.borderColor = UIColorFromRGBWithAlpha(0x252525, 0.7).CGColor;
        
        [self registerNib:[UINib nibWithNibName:@"HeaderSongCellView" bundle:[NSBundle mainBundle]] forHeaderFooterViewReuseIdentifier:@"HeaderSong"];
    }
    return self;
}

@end
