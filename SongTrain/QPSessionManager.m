//
//  QPSessionManager.m
//  SongTrain
//
//  Created by Quinton Petty on 2/10/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "QPSessionManager.h"
#import "QPMusicPlayerController.h"

@implementation QPSessionManager

+ (id)sessionManager {
    static QPSessionManager *sharedSessionManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"Session Manager allocated\n");
        sharedSessionManager = [[self alloc] init];
    });
    return sharedSessionManager;
}

- (id)init {
    if (self = [super init]) {
        service = SERVICE_TYPE;
        _pid = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
        
        _peerArray = [[NSMutableArray alloc] init];
        
        mainSession = [[MCSession alloc] initWithPeer:self.pid];
        mainSession.delegate = self;
        
        trainProtocol = [[SongtrainProtocol alloc] init];
        trainProtocol.delegate = self;
        
        browse = [[MCNearbyServiceBrowser alloc] initWithPeer:self.pid serviceType:service];
        browse.delegate = self;
        
        advert = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.pid discoveryInfo:nil serviceType:service];
        advert.delegate = self;
        
        _currentRole = NotConnected;
        _server = nil;
    }
    return self;
}

#pragma mark - Session Methods

- (void)createServer
{
    _currentRole = ServerConnection;
    [browse stopBrowsingForPeers];
    [advert startAdvertisingPeer];
}

- (void)connectToPeer:(MCPeerID*)peerID
{
    _currentRole = ClientConnection;
    [advert stopAdvertisingPeer];
    [browse invitePeer:peerID toSession:mainSession withContext:nil timeout:0];
}

- (void)restartSession
{
    [mainSession disconnect];
    [_peerArray removeAllObjects];
    [browse startBrowsingForPeers];
    _currentRole = NotConnected;
}

-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnecting) {
        NSLog(@"Connecting to %@", peerID.displayName);
        
    } else if (state == MCSessionStateConnected) {
        NSLog(@"Connected to %@", peerID.displayName);
        
        if (_currentRole == ClientConnection) {
            _server = peerID;
        }
        [self.delegate connectedToPeer:peerID];
  
    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"Disconnected from %@", peerID.displayName);
        
        if (_currentRole == ClientConnection) {
            _server = nil;
            _currentRole = NotConnected;
        }
        [self.delegate disconnectedFromPeer:peerID];
    }
}

-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"Got Stream: %@  from %@\n", streamName, [peerID displayName]);
}

-(void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    
}

-(void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSLog(@"Got some data from %@\n", peerID.displayName);
    
    NSLog(@"Recieved on thread: %@\n", [NSThread currentThread]);
    
    [trainProtocol messageToParse:data];
}

#pragma mark - Advertising Methods

-(void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{
    NSLog(@"Got Invite from %@", peerID.displayName);
    invitationHandler(YES,mainSession);
}

#pragma mark - Browsing Methods

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSLog(@"Added Peer: %@", peerID.displayName);
    [_peerArray addObject:peerID];
    [self.delegate availablePeersUpdated:self.peerArray];
}

-(void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"Removed Peer: %@", peerID.displayName);
    
    for (MCPeerID *peer in _peerArray) {
        if ([peer.displayName isEqualToString:peerID.displayName]) {
            [_peerArray removeObject:peer];
            break;
        }
    }
    [_peerArray removeObjectIdenticalTo:peerID];
    [self.delegate availablePeersUpdated:self.peerArray];
}

#pragma mark - Data Methods

- (void)sendData:(NSData*)data ToPeer:(MCPeerID*)peerID
{
    NSLog(@"Sending Data to %@\n", peerID.displayName);
    
    NSError *error;
    [mainSession sendData:data toPeers:[NSArray arrayWithObject:peerID] withMode:MCSessionSendDataReliable error:&error];
    
    if (error != nil) {
        NSLog(@"Error: %@\n", error.localizedDescription);
    }
    
    NSLog(@"This is the main Thread: %@\n", [NSThread isMainThread] ? @"YES" : @"NO");
}

- (void)sendDataToAllPeers:(NSData*)data
{
    for (MCPeerID *peer in mainSession.connectedPeers) {
        NSLog(@"Sending Data to %@\n", peer.displayName);
    }
    [mainSession sendData:data toPeers:mainSession.connectedPeers withMode:MCSessionSendDataReliable error:nil];
    NSLog(@"Sent Data to All Peers\n");
    NSLog(@"This is the main Thread: %@\n", [NSThread isMainThread] ? @"YES" : @"NO");
}

- (void)receivedSongArray:(NSMutableArray *)songArray
{
    NSLog(@"Recieved Song Array\n");
    
    NSLog(@"Thread: %@\n", [[NSThread currentThread] name]);
    
    if (_currentRole == ServerConnection) {
        NSLog(@"Sending ACK from server\n");
        //[[QPMusicPlayerController musicPlayer] addArrayOfSongsToPlaylist:songArray];
        [self sendDataToAllPeers:[SongtrainProtocol dataFromSongArray:[[QPMusicPlayerController musicPlayer] playlist]]];
    }
    else if (_currentRole == ClientConnection) {
        NSLog(@"Got Playlist from server\n");
        //[[QPMusicPlayerController musicPlayer] recievedPlaylistFromServer:songArray];
    }
}

- (void)requestToStartStreaming:(Song*)song
{
    //[[QPMusicPlayerController musicPlayer] fillOutStream:[mainSession startStreamWithName:@"temp" toPeer:self.server error:nil] FromSong:song];
}
- (void)requestToStopStreaming
{
    //[[QPMusicPlayerController musicPlayer] stopOutStream];
}
@end
