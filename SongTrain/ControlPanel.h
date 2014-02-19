//
//  ControlPanel.h
//  SongTrain
//
//  Created by Quinton Petty on 2/9/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>

enum ControlPanelButtonNames : NSInteger {
    AddButton = 1,
    SkipButton
};

@protocol ControlPanelDelegate <NSObject>

- (void)buttonPressed:(UIButton*)sender;

@end

@interface ControlPanel : UIImageView{
    UIButton *addButton;
    UIButton *skipButton;
    UILabel *timeLabel;
    
    UIProgressView *songProgress;
}

@property (weak, nonatomic) id <ControlPanelDelegate> delegate;
@property (nonatomic, assign, setter = setSongDuration:) NSRange songDuration;

- (void)setSongDuration:(NSRange)songDuration;

@end
