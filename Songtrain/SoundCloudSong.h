//
//  SoundCloudSong.h
//  Songtrain
//
//  Created by Quinton Petty on 10/18/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "Song.h"

@interface SoundCloudSong : Song <NSURLConnectionDataDelegate, NSStreamDelegate>

-(instancetype)initWithURL:(NSURL*)url;
-(instancetype)initWithSoundCloudDictionary:(NSDictionary*)dic;
-(instancetype)initWithSong:(Song*)song;

-(void)setOutputASBD:(AudioStreamBasicDescription)audioStreanBasicDescription;

@end
