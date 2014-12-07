//
//  ControlPanelView.h
//  Songtrain
//
//  Created by Quinton Petty on 10/2/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PassengerView : UIView

@property (weak) IBOutlet UIButton *addButton;
@property (weak) IBOutlet UILabel *currentTime;
@property (weak) IBOutlet UILabel *totalTime;
@end

@interface ConductorView : UIView

@property (weak) IBOutlet UIButton *addButton;
@property (weak) IBOutlet UIButton *playButton;
@property (weak) IBOutlet UILabel *currentTime;
@property (weak) IBOutlet UILabel *totalTime;

@end

typedef NS_ENUM(NSUInteger, ControlPanelType) {
    ControlPanelConductor,
    ControlPanelPassenger
};

@protocol ControlPanelDelegate <NSObject>

- (void)addPressed:(UIButton*)sender;
- (void)playOrPausedPressed:(UIButton*)sender;
- (void)skipPressed:(UIButton*)sender;

@end

@interface ControlPanelView : UIView

@property (weak) IBOutlet id <ControlPanelDelegate> delegate;

@property ConductorView *conductorView;
@property PassengerView *passengerView;

-(void)switchControlPanel:(ControlPanelType)type;
-(void)currentlyPlaying:(BOOL)playing;
-(void)updateTimeLabel:(NSRange)timeRange;

@end
