//
//  Animator.h
//  SongTrain
//
//  Created by Brandon Leventhal on 2/12/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Animator : NSObject <UIViewControllerAnimatedTransitioning>
{
    UIImageView *newView;
}
@property BOOL firstTime;
@property BOOL push;

@end
