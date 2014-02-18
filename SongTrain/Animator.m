//
//  Animator.m
//  SongTrain
//
//  Created by Brandon Leventhal on 2/12/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//
// Parallax animation delegate object

#import "Animator.h"

@implementation Animator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.firstTime = YES;
    }
    return self;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // Get to and from view controllers from the context using given keys
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *container = [transitionContext containerView];
    fromViewController.view.backgroundColor = [UIColor clearColor];


    //Blur Background Image, only create this on the first animation since the
    // container has a strong reference to it
    if (self.firstTime) {
        push = YES;
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


    // Animate the parallax, push alternates for pushing and popping
    // This might need to be changed for the info button, haven't attempted yet
    if (push) {

        toViewController.view.frame = CGRectMake(fromViewController.view.frame.size.width, 0, fromViewController.view.frame.size.width, fromViewController.view.frame.size.height);

        // Timing can be altered
        [UIView animateKeyframesWithDuration:ANIMATION_DURATION delay:0 options:0 animations:^{
            newView.transform = CGAffineTransformMakeTranslation(-fromViewController.view.frame.size.width / 2, 0);
            toViewController.view.transform = CGAffineTransformMakeTranslation(-fromViewController.view.frame.size.width, 0);
            fromViewController.view.transform = CGAffineTransformMakeTranslation(-fromViewController.view.frame.size.width - 2, 0);
        } completion:^(BOOL finished) {
            push = !push;
            [transitionContext completeTransition:finished];
        }];
    } else {

        toViewController.view.frame = CGRectMake(container.frame.origin.x - fromViewController.view.frame.size.width - 2, container.frame.origin.y, fromViewController.view.frame.size.width, fromViewController.view.frame.size.height);
        fromViewController.view.frame = CGRectMake(container.frame.origin.x, container.frame.origin.y, toViewController.view.frame.size.width, toViewController.view.frame.size.height);

        // Timing can be altered
        [UIView animateKeyframesWithDuration:ANIMATION_DURATION delay:0 options:0 animations:^{
            newView.transform = CGAffineTransformMakeTranslation(container.bounds.origin.x, 0);
            toViewController.view.transform = CGAffineTransformMakeTranslation(container.frame.origin.x, 0);
            fromViewController.view.transform = CGAffineTransformMakeTranslation(2, 0);
        } completion:^(BOOL finished) {
            push = !push;
            [transitionContext completeTransition:finished];
        }];
    }

}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // This can be altered.
    return ANIMATION_DURATION;
}

@end