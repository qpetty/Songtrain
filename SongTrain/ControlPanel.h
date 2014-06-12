//
//  ControlPanel.h
//  SongTrain
//
//  Created by Quinton Petty on 2/9/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>

#define BUTTON_SIZE 40


enum ControlPanelButtonNames : NSInteger {
    AddButton = 1,
    SkipButton,
    PlayButton
};

@protocol ControlPanelDelegate <NSObject>

- (void)buttonPressed:(UIButton*)sender;

@end

@interface ControlPanel : UIImageView{
    UIButton *addButton;
    CGRect location;
    UIProgressView *songProgress;
    NSUInteger currentSeconds, totalSeconds;
    int currentMinutes, totalMinutes;
}

@property (weak, nonatomic) id <ControlPanelDelegate> delegate;
@property (nonatomic, assign, setter = setSongDuration:) NSRange songDuration;
@property (nonatomic, assign, setter = setIsPlaying:) BOOL isPlaying;

- (void)setIsPlaying:(BOOL)isPlaying;
- (void)setSongDuration:(NSRange)songDuration;

@end
