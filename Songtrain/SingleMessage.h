//
//  CommunicationProtocol.h
//  SongTrain
//
//  Created by Quinton Petty on 2/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"

enum MessageTypes : NSInteger {
    AddSong = 1,
    RequestToRemoveSong,
    RemoveSong,
    SwitchSong,
    SkipSong,
    SkipVote,
    AlbumRequest,
    AlbumImage,
    PrepareSong,
    MusicPacketRequest,
    MusicPacket,
    FinishedStreaming,
    CurrentTime,
    CurrentSong,
    Booted
};

@interface SingleMessage : NSObject

@property (nonatomic) NSInteger message;
@property (strong, nonatomic) Song *song;
@property (nonatomic) NSInteger firstIndex, secondIndex;
@property (strong, nonatomic) NSData *data;

@end
