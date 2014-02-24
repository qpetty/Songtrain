//
//  QPOutputStreamer.h
//  SongTrain
//
//  Created by Quinton Petty on 2/24/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface QPOutputStreamer : NSObject <NSStreamDelegate>

- (void)setOutputStream:(NSOutputStream*)outputStream withURL:(NSURL *)url;

@end
