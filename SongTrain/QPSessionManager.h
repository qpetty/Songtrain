//
//  QPSessionManager.h
//  SongTrain
//
//  Created by Quinton Petty on 2/10/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "SongtrainProtocol.h"

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

@class QPMusicPlayerController;

@interface QPSessionManager : NSObject <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, SongtrainProtocolDelegate>{
    MCNearbyServiceBrowser *browse;
    MCNearbyServiceAdvertiser *advert;
    NSString *service;
    
    SongtrainProtocol *trainProtocol;
}

@property (weak, nonatomic) id <QPSessionManagerDelegate> delegate;
@property (nonatomic, retain, readonly) MCSession *mainSession;
@property (nonatomic, retain, readonly) MCPeerID *pid;
@property (nonatomic, retain, readonly) MCPeerID *server;
@property (nonatomic, retain, readonly) NSMutableArray *peerArray;
@property (nonatomic, assign, readonly) NSUInteger currentRole;

+ (id)sessionManager;

- (void)createServer;
- (void)connectToPeer:(MCPeerID*)peerID;

- (void)startBrowsing;
- (void)stopBrowsing;

- (void)sendData:(NSData*)data ToPeer:(MCPeerID*)peerID;
- (void)sendDataToAllPeers:(NSData*)data;
@end
