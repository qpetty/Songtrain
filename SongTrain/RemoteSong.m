//
//  RemoteSong.m
//  SongTrain
//
//  Created by Quinton Petty on 5/2/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "RemoteSong.h"

@implementation RemoteSong {
    BOOL sentRequest;
}

- (instancetype)initWithSong:(Song*)song fromPeer:(MCPeerID*)peer
{
    if (self = [super init]) {
        self.peer = peer;
        self.title = song.title;
        self.artistName = song.artistName;
        self.persistantID = song.persistantID;
        self.url = song.url;
        self.songLength = song.songLength;
        
        image = nil;
        sentRequest = NO;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.peer = [coder decodeObjectForKey:@"peer"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:self.peer forKey:@"peer"];
}

- (int)getMusicPackets:(UInt32*)numOfPackets forBuffer:(AudioBufferList*)ioData
{
    return 3;
}

- (UIImage*)getAlbumImage
{
    if (image)
        return image;
    
    if (sentRequest == NO){
        [[QPSessionManager sessionManager] requestAlbumArtwork:self];
        sentRequest = YES;
    }
    return nil;
}

@end
