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
    NotConnected = 1,
    ServerConnection,
    ClientConnection
};

@protocol QPSessionManagerDelegate <NSObject>

- (void)connectedToPeer:(MCPeerID*)peerID;
- (void)disconnectedFromPeer:(MCPeerID*)peerID;

@optional
- (void)availablePeersUpdated:(NSMutableArray*)peerArray;

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

@property (weak, nonatomic) id <QPSessionManagerDelegate> delegate;
//@property (atomic, strong, readonly) MCSession *mainSession;
@property (atomic, retain, readonly) MCPeerID *pid;
@property (atomic, retain, readonly) MCPeerID *server;
@property (atomic, retain, readonly) NSMutableArray *peerArray;
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
@end
