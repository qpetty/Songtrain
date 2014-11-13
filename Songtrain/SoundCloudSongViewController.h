//
//  SoundCloudSongViewController.h
//  Songtrain
//
//  Created by Quinton Petty on 11/1/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "TabViewController.h"
#import "QPSessionManager.h"

static const int kSoundCloudSongInitalLoad = 11;
static const int kSoundCloudSongNextLoad = 5;

@interface SoundCloudSongViewController : TabViewController

@property NSString *location;
@property (setter=updateTracks:) NSArray *tracks;

-(instancetype)initWithTracks:(NSArray*)arrayOfTracks andURL:(NSString*)url;

@end
