//
//  SoundCloudSong.h
//  Songtrain
//
//  Created by Quinton Petty on 10/18/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "Song.h"

@interface SoundCloudSong : Song

-(instancetype)initWithURL:(NSURL*)url;

@property (strong, nonatomic) NSURL *url;

@end
