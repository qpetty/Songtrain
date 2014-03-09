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

struct GraphHelper {
    AudioConverterRef converter;
    TPCircularBuffer audioBuffer;
};

@interface QPInputStreamer : NSObject

@property (nonatomic, retain) Song *currentSong;

- (void)setInputStream:(NSInputStream*)inputStream;

@end
