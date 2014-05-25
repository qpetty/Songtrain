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
        
        _connectedPeersArray = [[NSMutableArray alloc] init];
        
        mainSession = [[MCSession alloc] initWithPeer:self.pid];
        mainSession.delegate = self;
        
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
    [[QPMusicPlayerController musicPlayer] resetToServer];
    [[QPMusicPlayerController musicPlayer] addObserver:self forKeyPath:@"currentSong" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)connectToPeer:(MCPeerID*)peerID
{
    _currentRole = ClientConnection;
    [[QPMusicPlayerController musicPlayer] resetToClient];
    [browse stopBrowsingForPeers];
    [browse invitePeer:peerID toSession:mainSession withContext:nil timeout:0];
}

- (void)restartSession
{
    [mainSession disconnect];
    [_peerArray removeAllObjects];
    [advert stopAdvertisingPeer];
    [browse startBrowsingForPeers];
    if (_currentRole == ServerConnection) {
        [[QPMusicPlayerController musicPlayer] removeObserver:self forKeyPath:@"currentSong"];
    }
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
            [browse stopBrowsingForPeers];
        }
        [[self mutableArrayValueForKey:@"connectedPeersArray"] addObject:peerID];
        [self.delegate connectedToPeer:peerID];
  
    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"Disconnected from %@", peerID.displayName);
        
        if (_currentRole == ClientConnection) {
            _server = nil;
            _currentRole = NotConnected;
            [browse startBrowsingForPeers];
        }
        [[self mutableArrayValueForKey:@"connectedPeersArray"] removeObject:peerID];
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
    
    //NSLog(@"Recieved on thread: %@\n", [NSThread currentThread]);
    
    SingleMessage *mess = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (mess.message == AlbumRequest) {
            [self sendAlbumArtwork:[self findSong:mess.song] to:peerID];
        }
        else if (mess.message == AlbumImage) {
            [self findSong:mess.song].albumImage = [NSKeyedUnarchiver unarchiveObjectWithData:mess.data];
        }
        else if (mess.message == AddSong && _currentRole == ServerConnection) {
            RemoteSong *newSong = [[RemoteSong alloc] initWithSong:mess.song fromPeer:peerID];
            [[QPMusicPlayerController musicPlayer] addSongToPlaylist:newSong];
            [self addSongToAllPeers:newSong];
        }
        else if (mess.message == AddSong && _currentRole == ClientConnection) {
            Song *newSong;
            
            if ([mess.song isMemberOfClass:[RemoteSong class]] && [((RemoteSong*)mess.song).peer isEqual:self.pid]) {
                newSong = [[LocalSong alloc] initLocalSongFromSong:mess.song];
            }
            else {
                newSong = [[RemoteSong alloc] initWithSong:mess.song fromPeer:peerID];
            }
            [[QPMusicPlayerController musicPlayer] addSongToPlaylist:newSong];
        }
        else if (mess.message == SkipSong && _currentRole == ClientConnection) {
            [[QPMusicPlayerController musicPlayer] nextSong];
        }
        else if (mess.message == RemoveSong && _currentRole == ClientConnection) {
            [[QPMusicPlayerController musicPlayer] removeSongFromPlaylist:mess.firstIndex];
        }
        else if (mess.message == SwitchSong && _currentRole == ClientConnection) {
            NSLog(@"first: %ld   second: %ld\n", (long)mess.firstIndex, (long)mess.secondIndex);
            [[QPMusicPlayerController musicPlayer] switchSongFromIndex:mess.firstIndex to:mess.secondIndex];
        }
        else if (mess.message == StartStreaming) {
            NSLog(@"Start Streaming\n");
        }
    });
}

- (Song*)findSong:(Song*)song
{
    if ([[[QPMusicPlayerController musicPlayer] currentSong] isEqual:song]) {
        return [[QPMusicPlayerController musicPlayer] currentSong];
    }
    
    for (Song *songFromList in [[QPMusicPlayerController musicPlayer] playlist]) {
        if ([song isEqual:songFromList]) {
            return songFromList;
        }
    }
    return nil;
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
}

- (void)sendDataToAllPeers:(NSData*)data
{
    [mainSession sendData:data toPeers:mainSession.connectedPeers withMode:MCSessionSendDataReliable error:nil];
    NSLog(@"Sent Data to All Peers\n");
    //NSLog(@"This is the main Thread: %@\n", [NSThread isMainThread] ? @"YES" : @"NO");
}

- (void)nextSong:(Song*)song
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = SkipSong;
    message.song = song;
    [self sendDataToAllPeers:[NSKeyedArchiver archivedDataWithRootObject:message]];
}

- (void)addSongToServer:(Song*)song
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = AddSong;
    message.song = song;
    [self sendData:[NSKeyedArchiver archivedDataWithRootObject:message] ToPeer:self.server];
}

- (void)addSong:(Song*)song toPeer:(MCPeerID*)peer
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = AddSong;
    message.song = song;
    [self sendData:[NSKeyedArchiver archivedDataWithRootObject:message] ToPeer:peer];
}

- (void)addSongToAllPeers:(Song*)song
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = AddSong;
    message.song = song;
    [self sendDataToAllPeers:[NSKeyedArchiver archivedDataWithRootObject:message]];
}

//- (void)removeSongFromAllPeers:(Song*)song atIndex:(NSUInteger)ndx
- (void)removeSongFromAllPeersAtIndex:(NSUInteger)ndx
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = RemoveSong;
    //message.song = song;
    message.firstIndex = ndx;
    [self sendDataToAllPeers:[NSKeyedArchiver archivedDataWithRootObject:message]];
}

- (void)switchSongFrom:(NSUInteger)x to:(NSUInteger)y
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = SwitchSong;
    //message.song = song;
    message.firstIndex = x;
    message.secondIndex = y;
    [self sendDataToAllPeers:[NSKeyedArchiver archivedDataWithRootObject:message]];
}

- (void)requestAlbumArtwork:(RemoteSong*)song
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = AlbumRequest;
    message.song = song;
    [self sendData:[NSKeyedArchiver archivedDataWithRootObject:message] ToPeer:song.peer];
}

- (void)sendAlbumArtwork:(Song*)song to:(MCPeerID*)peer
{
    if (song.albumImage == nil){
        NSLog(@"No Album Image to send\n");
        return;
    }
    
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = AlbumImage;
    message.song = song;
    message.data = [NSKeyedArchiver archivedDataWithRootObject:song.albumImage];
    
    [self sendData:[NSKeyedArchiver archivedDataWithRootObject:message] ToPeer:peer];
    //NSLog(@"Sending Image %@\n", song.albumImage);
}

- (void)requestToStartStreaming:(RemoteSong*)song
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = StartStreaming;
    message.song = song;
    [self sendData:[NSKeyedArchiver archivedDataWithRootObject:message] ToPeer:song.peer];
}
- (void)requestToStopStreaming
{
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([keyPath isEqualToString:@"currentSong"]) {
            [self nextSong:[QPMusicPlayerController musicPlayer].currentSong];
        }
    });
}

@end
