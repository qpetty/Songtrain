//
//  QPInputStreamer.h
//  SongTrain
//
//  Created by Quinton Petty on 2/25/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>

#import "TPCircularBuffer.h"

static const int kBufferLength = 32768 * 4;

@interface QPInputStreamer : NSObject

- (void)setInputStream:(NSInputStream*)inputStream;

@end
