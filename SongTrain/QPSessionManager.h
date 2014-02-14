//
//  QPSessionManager.h
//  SongTrain
//
//  Created by Quinton Petty on 2/10/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface QPSessionManager : NSObject <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate>{
    MCNearbyServiceBrowser *browse;
    NSString *service;
}

@property (nonatomic, retain, readonly) MCSession *mainSession;
@property (nonatomic, retain, readonly) MCPeerID *pid;
@property (nonatomic, retain, readonly) NSMutableArray *peerArray;

+ (id)sessionManager;

@end
