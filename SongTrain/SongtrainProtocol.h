//
//  SongtrainProtocol.h
//  SongTrain
//
//  Created by Quinton Petty on 2/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SingleMessage.h"

enum MessageTypes : NSInteger {
    SongArray = 1,
    StartStreaming = 2,
    StopStreaming = 3
};

@protocol SongtrainProtocolDelegate <NSObject>

- (void)receivedSongArray:(NSMutableArray*)songArray;

@optional
- (void)requestToStartStreaming:(NSURL*) url;
- (void)requestToStopStreaming;

@end

@interface SongtrainProtocol : NSObject

@property (weak, nonatomic) id <SongtrainProtocolDelegate> delegate;

-(void)messageToParse:(NSData*)data;
+(NSData*)dataFromSongArray:(NSMutableArray*)array;
+(NSData*)dataFromURL:(NSURL*)url;

@end
