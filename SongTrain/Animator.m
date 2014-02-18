//
//  Animator.m
//  SongTrain
//
//  Created by Brandon Leventhal on 2/12/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//
// Parallax animation delegate object

#import "Animator.h"

#define TRANSITION_TIME 0.5
#define NUMBER_OF_VIEWS 3.0

@implementation Animator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.firstTime = YES;
    }
    return self;
}

- (instancetype)initWithImage:(UIImageView *)parallaxImage
{
    self = [super init];
    if (self) {
        self.firstTime = YES;
    }
    // Consider making all this generic to be turned into a library
    return self;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // Get to and from view controllers from the context using given keys
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *container = [transitionContext containerView];

    //Blur Background Image, only create this on the first animation since the
    // container has a strong reference to it
    if (self.firstTime) {
        CIImage *gaussBlurBackground = [[CIImage alloc] initWithImage:[UIImage imageNamed:@"splash.png"]];
        CIFilter *gaussianBlurFilter = [CIFilter filterWithName: @"CIGaussianBlur"];
        [gaussianBlurFilter setValue:gaussBlurBackground forKey: @"inputImage"];
        [gaussianBlurFilter setValue:[NSNumber numberWithFloat: 8] forKey: @"inputRadius"];
        CIImage *resultImage = [gaussianBlurFilter valueForKey: @"outputImage"];
        UIImage *blurredImage = [[UIImage alloc] initWithCIImage:resultImage];
        newView = [[UIImageView alloc] initWithFrame:toViewController.view.bounds];

        
        newView.frame = CGRectMake(fromViewController.view.bounds.origin.x - 30, fromViewController.view.bounds.origin.y - 15, fromViewController.view.bounds.size.width * 1.5 + 60, fromViewController.view.bounds.size.height + 30);
        newView.image = blurredImage;
        [container addSubview:newView];
        self.firstTime = NO;
    }



    // Clear the backgrounds to make parallax show through
    fromViewController.view.backgroundColor = [UIColor clearColor];
    toViewController.view.backgroundColor = [UIColor clearColor];

    // Add views to the container superview
    [container insertSubview:fromViewController.view aboveSubview:newView];
    [container insertSubview:toViewController.view aboveSubview:newView];


    // Animate the parallax, self.push alternates for self.pushing and popping
    // This might need to be changed for the info button, haven't attempted yet
    if (self.push) {

        toViewController.view.frame = CGRectMake(fromViewController.view.frame.size.width, 0, fromViewController.view.frame.size.width, fromViewController.view.frame.size.height);

        [UIView animateKeyframesWithDuration:TRANSITION_TIME delay:0 options:0 animations:^{
            newView.frame = CGRectMake(newView.frame.origin.x - (newView.frame.size.width - toViewController.view.frame.size.width)/NUMBER_OF_VIEWS, newView.frame.origin.y, newView.frame.size.width, newView.frame.size.height);
        } completion:^(BOOL finished) {
            //[transitionContext completeTransition:finished];
        }];
        // Timing can be altered
        [UIView animateKeyframesWithDuration:TRANSITION_TIME delay:0 options:0 animations:^{
            //newView.frame = CGRectMake(newView.frame.origin.x - (newView.frame.size.width - toViewController.view.frame.size.width)/NUMBER_OF_VIEWS, newView.frame.origin.y, newView.frame.size.width, newView.frame.size.height);
            toViewController.view.frame = CGRectMake(toViewController.view.frame.origin.x - toViewController.view.frame.size.width, toViewController.view.frame.origin.y, toViewController.view.frame.size.width, toViewController.view.frame.size.height);

            fromViewController.view.frame = CGRectMake(fromViewController.view.frame.origin.x - fromViewController.view.frame.size.width, fromViewController.view.frame.origin.y, fromViewController.view.frame.size.width, fromViewController.view.frame.size.height);
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:finished];
        }];
    } else {

        toViewController.view.frame = CGRectMake(container.frame.origin.x - fromViewController.view.frame.size.width - 2, container.frame.origin.y, fromViewController.view.frame.size.width, fromViewController.view.frame.size.height);
        fromViewController.view.frame = CGRectMake(container.frame.origin.x, container.frame.origin.y, toViewController.view.frame.size.width, toViewController.view.frame.size.height);

        // Timing can be altered
        [UIView animateKeyframesWithDuration:TRANSITION_TIME delay:0 options:0 animations:^{
            toViewController.view.frame = CGRectMake(toViewController.view.frame.origin.x + toViewController.view.frame.size.width + 2, toViewController.view.frame.origin.y, toViewController.view.frame.size.width, toViewController.view.frame.size.height);
            fromViewController.view.frame = CGRectMake(fromViewController.view.frame.origin.x + fromViewController.view.frame.size.width, fromViewController.view.frame.origin.y, fromViewController.view.frame.size.width, fromViewController.view.frame.size.height);
            newView.frame = CGRectMake(newView.frame.origin.x + (newView.frame.size.width - toViewController.view.frame.size.width)/NUMBER_OF_VIEWS, newView.frame.origin.y, newView.frame.size.width, newView.frame.size.height);

        } completion:^(BOOL finished) {
            [transitionContext completeTransition:finished];
        }];
    }

}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // This can be altered.
    return TRANSITION_TIME;
}

@end
