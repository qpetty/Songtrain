//
//  SoundCloudSong.h
//  Songtrain
//
//  Created by Quinton Petty on 10/18/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "Song.h"

@interface SoundCloudSong : Song <NSURLConnectionDataDelegate, NSStreamDelegate>

@property NSURL *musicURL;
@property NSURL *artworkURL;

-(instancetype)initWithURL:(NSURL *)url andPeer:(MCPeerID*)peer;
-(instancetype)initWithSoundCloudDictionary:(NSDictionary*)dic andPeer:(MCPeerID*)peer;

-(void)setOutputASBD:(AudioStreamBasicDescription)audioStreanBasicDescription;

@end
