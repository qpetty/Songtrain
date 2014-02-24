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
    
    MCSession *mainSession;
}

@property (weak, nonatomic) id <QPSessionManagerDelegate> delegate;
//@property (atomic, strong, readonly) MCSession *mainSession;
@property (atomic, retain, readonly) MCPeerID *pid;
@property (atomic, retain, readonly) MCPeerID *server;
@property (atomic, retain, readonly) NSMutableArray *peerArray;
@property (atomic, assign, readonly) NSUInteger currentRole;

+ (id)sessionManager;

- (void)createServer;
- (void)connectToPeer:(MCPeerID*)peerID;
- (void)restartSession;

- (void)sendData:(NSData*)data ToPeer:(MCPeerID*)peerID;
- (void)sendDataToAllPeers:(NSData*)data;
@end
