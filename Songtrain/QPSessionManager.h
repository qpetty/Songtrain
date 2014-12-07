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

- (void)foundPeer:(MCPeerID*)peerID;
- (void)lostPeer:(MCPeerID*)peerID atIndex:(NSUInteger)ndx;

@end

@protocol QPSessionDelegate <NSObject>

- (void)connectedToPeer:(MCPeerID*)peerID;
- (void)disconnectedFromPeer:(MCPeerID*)peerID atIndex:(NSUInteger)ndx;

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

@property (weak, nonatomic) id <QPBrowsingManagerDelegate> browsingDelegate;
@property (weak, nonatomic) id <QPSessionDelegate> sessionDelegate;
@property (atomic, readonly) MCPeerID *pid;
@property (atomic, readonly) MCPeerID *server;
@property (atomic, readonly) NSMutableArray *peerArray;
@property (atomic, readonly) NSMutableArray *connectedPeerArray;
@property (atomic, assign, readonly) enum CurrentConnectionRole currentRole;

+ (id)sessionManager;

- (void)createServer;
- (void)startBrowsingForTrains;
- (void)stopBrowsingForTrains;

- (void)connectToPeer:(MCPeerID*)peerID;
- (void)stopConnectingToSession;
- (void)restartSession;

- (void)nextSong:(Song*)song;
- (void)addSongToServer:(Song*)song;
- (void)addSong:(Song*)song toPeer:(MCPeerID*)peer;
- (void)addSongToAllPeers:(Song*)song;

- (void)requestToRemoveSong:(Song*)song;
- (void)removeSongFromAllPeersAtIndex:(NSUInteger)ndx;
- (void)switchSongFrom:(NSUInteger)x to:(NSUInteger)y;
- (void)requestAlbumArtwork:(Song*)song;
- (void)sendAlbumArtworkToEveryone:(Song*)song;

- (void)prepareRemoteSong:(Song*)song;
- (void)requestMusicDataForSong:(Song*)song withAvailableBytes:(NSInteger)bytes;

- (void)bootPeer:(MCPeerID*)peer;
@end
