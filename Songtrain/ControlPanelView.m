//
//  ControlPanelView.m
//  Songtrain
//
//  Created by Quinton Petty on 10/2/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "ControlPanelView.h"

#define CONTROLPANEL_XIB_NAME @"ControlPanelView"

@implementation PassengerView

@end

@implementation ConductorView

@end

@implementation ControlPanelView {
    UIButton *playbutton;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        [self loadViews];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self loadViews];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self loadViews];
    }
    return self;
}

-(void)loadViews {
    _conductorView = [[[NSBundle mainBundle] loadNibNamed:CONTROLPANEL_XIB_NAME owner:self options:nil] firstObject];
    [self switchControlPanel:ControlPanelConductor];
    _passengerView = [[[NSBundle mainBundle] loadNibNamed:CONTROLPANEL_XIB_NAME owner:self options:nil] lastObject];
}

-(void)switchControlPanel:(ControlPanelType)type {
    UIView *newView = type == ControlPanelConductor ? self.conductorView : self.passengerView;
    [self.conductorView removeFromSuperview];
    [self.passengerView removeFromSuperview];
    [self addSubview:newView];
}

-(void)layoutSubviews {
    self.conductorView.frame = self.bounds;
    self.passengerView.frame = self.bounds;
}

-(void)currentlyPlaying:(BOOL)playing {
    [self.conductorView.playButton setImage:playing ? [UIImage imageNamed:@"pause"] :[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
}

-(void)updateTimeLabel:(NSRange)timeRange {
    NSString *currentTimeString = [self timeStringFromSeconds:timeRange.location];
    NSString *totalTimeString = [self timeStringFromSeconds:timeRange.length];
    
    //Conductor Label
    self.conductorView.currentTime.text = currentTimeString;
    self.conductorView.totalTime.text = totalTimeString;
    
    //Passenger Label
    self.passengerView.currentTime.text = currentTimeString;
    self.passengerView.totalTime.text = totalTimeString;
    //Use for the longer time format if we ever need it. Will need to remove the currentTime and totalTime IBOutlets and replace with a single time Label
    //self.passengerView.time.text = [NSString stringWithFormat:@"%@-%@", currentTimeString, totalTimeString];
}

-(NSString*)timeStringFromSeconds:(NSUInteger)sec {
    NSUInteger minutes = 0;
    
    while (sec >= 60) {
        minutes++;
        sec -= 60;
    }
    
    return [NSString stringWithFormat:@"%lu:%.2lu", (unsigned long)minutes, (unsigned long)sec];
}

-(IBAction)addButtonWasPressed:(id)sender {
    [self.delegate addPressed:sender];
}

-(IBAction)skipButtonWasPressed:(id)sender {
    [self.delegate skipPressed:sender];
}

-(IBAction)playButtonWasPressed:(id)sender {
    [self.delegate playOrPausedPressed:sender];
}
@end
