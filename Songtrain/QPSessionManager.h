//
//  QPSessionManager.h
//  SongTrain
//
//  Created by Quinton Petty on 2/10/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "SingleMessage.h"
#import "QPMusicPlayerController.h"

enum CurrentConnectionRole : NSInteger {
    ServerConnection = 1,
    ClientConnection
};

@protocol QPBrowsingManagerDelegate <NSObject>

- (void)connectedToPeer:(MCPeerID*)peerID;
- (void)disconnectedFromPeer:(MCPeerID*)peerID;

@end

@class RemoteSong;
@class QPMusicPlayerController;

static NSString *kSongtrainPeerID = @"SongtrainPeerID";

@interface QPSessionManager : NSObject <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate>{
    MCNearbyServiceBrowser *browse;
    MCNearbyServiceAdvertiser *advert;
    NSString *service;
    
    MCSession *mainSession;
}

@property (weak, nonatomic) id <QPBrowsingManagerDelegate> delegate;
@property (atomic, retain, readonly) MCPeerID *pid;
@property (atomic, retain, readonly) MCPeerID *server;
@property (atomic, retain, readonly) NSMutableArray *peerArray;
@property (atomic, strong, readonly) NSMutableArray *connectedPeerArray;
@property (atomic, assign, readonly) enum CurrentConnectionRole currentRole;

+ (id)sessionManager;

- (void)createServer;
- (void)startBrowsingForTrains;
- (void)stopBrowsingForTrains;

- (void)connectToPeer:(MCPeerID*)peerID;
- (void)restartSession;

- (void)nextSong:(Song*)song;
- (void)addSongToServer:(Song*)song;
- (void)addSong:(Song*)song toPeer:(MCPeerID*)peer;
- (void)addSongToAllPeers:(Song*)song;
- (void)removeSongFromAllPeersAtIndex:(NSUInteger)ndx;
- (void)switchSongFrom:(NSUInteger)x to:(NSUInteger)y;
- (void)requestAlbumArtwork:(RemoteSong*)song;

- (void)requestMusicDataForSong:(RemoteSong*)song withAvailableBytes:(NSInteger)bytes;

- (void)bootPeer:(MCPeerID*)peer;
@end
