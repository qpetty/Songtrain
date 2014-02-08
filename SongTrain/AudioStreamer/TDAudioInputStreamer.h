//
//  TDAudioInputStreamer.h
//  TDAudioStreamer
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>

@protocol TDAudioInputStreamDelegate <NSObject>

@required
- (void)finishedPlayingSong;

@end

@interface TDAudioInputStreamer : NSObject

@property (assign, nonatomic) id<TDAudioInputStreamDelegate> delegate;

@property (assign, nonatomic) UInt32 audioStreamReadMaxLength;
@property (assign, nonatomic) UInt32 audioQueueBufferSize;
@property (assign, nonatomic) UInt32 audioQueueBufferCount;

- (instancetype)initWithInputStream:(NSInputStream *)inputStream;

- (void)start;
- (void)resume;
- (void)pause;
- (void)stop;

@end
