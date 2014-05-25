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

- (BOOL)isEqual:(id)object
{
    if (![super isEqual:object])
        return false;
    
    if (![object isMemberOfClass:[self class]])
        return false;
    
    if (((RemoteSong*)object).peer != self.peer)
        return false;
    
    return true;
}

- (UIImage*)getAlbumImage
{
    if (image)
        return image;
    
    //QPSessionManager *sessionman = [QPSessionManager sessionManager];
    //NSLog(@"Comparing %@ and %@\n", self.peer.displayName, sessionman.pid);
    
    /*
    if ([self.peer isEqual:[[QPSessionManager sessionManager] pid]]) {
        MPMediaQuery *query = [[MPMediaQuery alloc] init];
        [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:self.url forProperty:MPMediaItemPropertyAssetURL]];
        if ([[query items] count] == 0) {
            NSLog(@"Could not query url\n");
            return nil;
        }
        
        MPMediaItemArtwork *albumItem = [[[query items] firstObject] valueForProperty:MPMediaItemPropertyArtwork];
        if (albumItem) {
            image = [albumItem imageWithSize:CGSizeMake(albumItem.bounds.size.width, albumItem.bounds.size.height)];
            return image;
        }
        else {
            NSLog(@"No Album Image\n");
            return nil;
        }
    }
    
    */
    if (sentRequest == NO){
        [[QPSessionManager sessionManager] requestAlbumArtwork:self];
        sentRequest = YES;
    }
    return nil;
}

@end
