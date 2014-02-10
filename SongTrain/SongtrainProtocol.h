//
//  SongtrainProtocol.h
//  SongTrain
//
//  Created by Quinton Petty on 2/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "SingleMessage.h"
#import "Song.h"

enum MessageTypes : NSInteger {
    SongArray = 1,
    StartStreaming,
    StopStreaming
};

@protocol SongtrainProtocolDelegate <NSObject>

- (void)receivedSongArray:(NSMutableArray*)songArray;

@optional
- (void)requestToStartStreaming:(Song*)song;
- (void)requestToStopStreaming;

@end

@interface SongtrainProtocol : NSObject

@property (weak, nonatomic) id <SongtrainProtocolDelegate> delegate;

-(void)messageToParse:(NSData*)data;
+(NSData*)dataFromSongArray:(NSMutableArray*)array;
+(NSData*)dataFromMedia:(Song*)item;

@end
