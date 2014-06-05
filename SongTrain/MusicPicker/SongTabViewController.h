//
//  SongTabViewController.h
//  SongTrain
//
//  Created by Quinton Petty on 4/7/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "TabViewController.h"

@interface SongTabViewController : TabViewController

-(id)initWithQuery:(MPMediaQuery*)query;

@end
