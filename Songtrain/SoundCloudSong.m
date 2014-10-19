//
//  SoundCloudSong.m
//  Songtrain
//
//  Created by Quinton Petty on 10/18/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "SoundCloudSong.h"
#import "CocoaSoundCloudUI/Sources/SoundCloudUI/SCUI.h"

@implementation SoundCloudSong

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        self.url = url;
        [self getSongInfo];
    }
    return self;
}

- (void)getSongInfo {
    SCRequestResponseHandler handler;
    handler = ^(NSURLResponse *response, NSData *data, NSError *error) {
        NSError *jsonError = nil;
        NSJSONSerialization *jsonResponse = [NSJSONSerialization
                                             JSONObjectWithData:data
                                             options:0
                                             error:&jsonError];
        if (!jsonError && [jsonResponse isKindOfClass:[NSDictionary class]]) {
            NSDictionary *songDictionary = (NSDictionary *)jsonResponse;
            //NSLog(@"Json response: %@", songDictionary);
            self.title = songDictionary[@"title"];
            self.artistName = songDictionary[@"user"][@"username"];
        } else if (jsonError) {
            NSLog(@"Error: %@", jsonError);
        }
    };
    
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:self.url
             usingParameters:nil
                 withAccount:[SCSoundCloud account]
      sendingProgressHandler:nil
             responseHandler:handler];
}

- (BOOL)isEqual:(id)object
{
    if ([super isEqual:object] == NO)
        return false;
    if (![object isKindOfClass:[SoundCloudSong class]])
        return false;
    if (![((SoundCloudSong*)object).url isEqual:self.url])
        return false;
    
    return true;
}

@end
