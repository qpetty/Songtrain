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

-(void)setOutputASBD:(AudioStreamBasicDescription)audioStreanBasicDescription;

@property (strong, nonatomic) NSURL *url;
@property (readonly) NSString *streamURL;

@end
