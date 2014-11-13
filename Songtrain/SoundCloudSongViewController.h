//
//  SoundCloudSongViewController.h
//  Songtrain
//
//  Created by Quinton Petty on 11/1/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "TabViewController.h"
#import "QPSessionManager.h"

@interface SoundCloudSongViewController : TabViewController

@property (setter=updateTracks:) NSArray *tracks;

-(instancetype)initWithTracks:(NSArray*)arrayOfTracks;

@end
