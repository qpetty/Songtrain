//
//  ControlPanelView.h
//  Songtrain
//
//  Created by Quinton Petty on 10/2/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

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

@property UIView *conductorView;
@property UIView *passengerView;

@property CGRect frame;

-(void)switchControlPanel:(ControlPanelType)type;

-(void)currentlyPlaying:(BOOL)playing;

/*
-(IBAction)addButtonWasPressed:(id)sender;
-(IBAction)skipButtonWasPressed:(id)sender;
-(IBAction)playButtonWasPressed:(id)sender;
*/
@end
