//
//  ControlPanelView.m
//  Songtrain
//
//  Created by Quinton Petty on 10/2/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "ControlPanelView.h"

#define CONTROLPANEL_XIB_NAME @"ControlPanelView"

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
    [super layoutSubviews];
    self.conductorView.frame = self.bounds;
    self.passengerView.frame = self.bounds;
}

-(void)currentlyPlaying:(BOOL)playing {
    //NSLog(@"updating play/pause, playing %@", playing == YES ? @"YES" : @"NO");
    /*
    NSLog(@"play button: %@", playbutton);
    dispatch_async(dispatch_get_main_queue(), ^{
        [playbutton setImage:playing ? [UIImage imageNamed:@"pause"] :[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    });
     */
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
