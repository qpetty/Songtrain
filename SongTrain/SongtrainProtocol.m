//
//  SongtrainProtocol.m
//  SongTrain
//
//  Created by Quinton Petty on 2/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "SongtrainProtocol.h"

@implementation SongtrainProtocol

/*
-(void)messageToParse:(NSData*)data
{
    SingleMessage *mess = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    if (mess.message == SongArray) {
        [self.delegate receivedSongArray:[NSKeyedUnarchiver unarchiveObjectWithData:mess.data]];
    }
    else if (mess.message == StartStreaming){
        [self.delegate requestToStartStreaming:[NSKeyedUnarchiver unarchiveObjectWithData:mess.data]];
    }
    else if (mess.message == StopStreaming){
        [self.delegate requestToStopStreaming];
    }
}

+(NSData*)dataFromSongArray:(NSMutableArray*)array
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = SongArray;
    message.data = [NSKeyedArchiver archivedDataWithRootObject:array];
    return [NSKeyedArchiver archivedDataWithRootObject:message];
}

+(NSData*)dataFromMedia:(Song*)item
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = StartStreaming;
    message.data = [NSKeyedArchiver archivedDataWithRootObject:item];
    return [NSKeyedArchiver archivedDataWithRootObject:message];
}
*/
@end
