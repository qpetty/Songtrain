//
//  QPSessionManager.m
//  SongTrain
//
//  Created by Quinton Petty on 2/10/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "QPSessionManager.h"
#import "QPMusicPlayerController.h"

#define SERVICE_TYPE @"Songtrain"

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
        _pid = [self getDevicePeerID];
        
        _peerArray = [[NSMutableArray alloc] init];
        _connectedPeerArray = [[NSMutableArray alloc] init];
        
        mainSession = [[MCSession alloc] initWithPeer:self.pid];
        mainSession.delegate = self;
        
        browse = [[MCNearbyServiceBrowser alloc] initWithPeer:self.pid serviceType:service];
        browse.delegate = self;
        
        advert = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.pid discoveryInfo:nil serviceType:service];
        advert.delegate = self;
        
        _currentRole = ServerConnection;
        _server = _pid;
    }
    return self;
}

- (MCPeerID*)getDevicePeerID
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *peerData = [defaults dataForKey:kSongtrainPeerID];
    MCPeerID *peerID;
    
    if (peerData == nil) {
        peerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
        peerData = [NSKeyedArchiver archivedDataWithRootObject:peerID];
        [defaults setObject:peerData forKey:kSongtrainPeerID];
        [defaults synchronize];
    }
    else {
        peerID = [NSKeyedUnarchiver unarchiveObjectWithData:peerData];
    }
    
    return peerID;
}

#pragma mark - Session Methods

- (void)createServer
{
    _currentRole = ServerConnection;
    [self willChangeValueForKey:@"server"];
    _server = _pid;
    [self didChangeValueForKey:@"server"];
    [advert startAdvertisingPeer];
    [[QPMusicPlayerController sharedMusicPlayer] resetToServer];
    [[QPMusicPlayerController sharedMusicPlayer] addObserver:self forKeyPath:@"currentSong" options:NSKeyValueObservingOptionNew context:nil];
    [[QPMusicPlayerController sharedMusicPlayer] addObserver:self forKeyPath:@"currentSongTime" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)startBrowsingForTrains {
    [self willChangeValueForKey:@"peerArray"];
    [_peerArray removeAllObjects];
    [self didChangeValueForKey:@"peerArray"];
    [browse startBrowsingForPeers];
}

- (void)stopBrowsingForTrains {
    [browse stopBrowsingForPeers];
    [self willChangeValueForKey:@"peerArray"];
    [_peerArray removeAllObjects];
    [self didChangeValueForKey:@"peerArray"];
}

- (void)connectToPeer:(MCPeerID*)peerID
{
    _currentRole = ClientConnection;
    [advert stopAdvertisingPeer];
    [[QPMusicPlayerController sharedMusicPlayer] resetToClient];
    [browse invitePeer:peerID toSession:mainSession withContext:nil timeout:0];
    
    [self willChangeValueForKey:@"server"];
    _server = peerID;
    [self didChangeValueForKey:@"server"];
    
    [[QPMusicPlayerController sharedMusicPlayer] removeObserver:self forKeyPath:@"currentSong"];
    [[QPMusicPlayerController sharedMusicPlayer] removeObserver:self forKeyPath:@"currentSongTime"];
}

- (void)restartSession
{
    [mainSession disconnect];
    [self createServer];
}

-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnecting) {
        NSLog(@"Connecting to %@", peerID.displayName);
        
    } else if (state == MCSessionStateConnected) {
        NSLog(@"Connected to %@", peerID.displayName);
        [self willChangeValueForKey:@"connectedPeerArray"];
        [_connectedPeerArray addObject:peerID];
        [self didChangeValueForKey:@"connectedPeerArray"];
        
        if ([self.pid isEqual:self.server]) {
            NSLog(@"Giving songs to %@", peerID.displayName);
            [self addSong:[QPMusicPlayerController sharedMusicPlayer].currentSong toPeer:peerID];
            [self nextSong:[QPMusicPlayerController sharedMusicPlayer].currentSong forPeer:peerID];
            for (Song *s in [QPMusicPlayerController sharedMusicPlayer].playlist) {
                [self addSong:s toPeer:peerID];
            }
        }
    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"Disconnected from %@", peerID.displayName);
        [self willChangeValueForKey:@"connectedPeerArray"];
        [_connectedPeerArray removeObjectIdenticalTo:peerID];
        [self didChangeValueForKey:@"connectedPeerArray"];
         
        if (self.currentRole == ClientConnection && [peerID isEqual:self.server]) {
            [self restartSession];
        }
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
            RemoteSong *newSong = [[RemoteSong alloc] initWithSong:mess.song fromPeer:peerID andOutputASBD:*([QPMusicPlayerController sharedMusicPlayer].audioFormat)];
            [[QPMusicPlayerController sharedMusicPlayer] addSongToPlaylist:newSong];
            [self addSongToAllPeers:newSong];
        }
        else if (mess.message == AddSong && _currentRole == ClientConnection) {
            Song *newSong;
            
            if ([mess.song isMemberOfClass:[RemoteSong class]] && [((RemoteSong*)mess.song).peer isEqual:self.pid]) {
                newSong = [[LocalSong alloc] initLocalSongFromSong:mess.song WithOutputASBD:*([QPMusicPlayerController sharedMusicPlayer].audioFormat)];
            }
            else {
                newSong = [[RemoteSong alloc] initWithSong:mess.song fromPeer:peerID andOutputASBD:*([QPMusicPlayerController sharedMusicPlayer].audioFormat)];
            }
            [[QPMusicPlayerController sharedMusicPlayer] addSongToPlaylist:newSong];
        }
        else if (mess.message == SkipSong && _currentRole == ClientConnection) {
            [[QPMusicPlayerController sharedMusicPlayer] nextSong];
        }
        else if (mess.message == RemoveSong && _currentRole == ClientConnection) {
            [[QPMusicPlayerController sharedMusicPlayer] removeSongFromPlaylist:mess.firstIndex];
        }
        else if (mess.message == SwitchSong && _currentRole == ClientConnection) {
            NSLog(@"first: %ld   second: %ld\n", (long)mess.firstIndex, (long)mess.secondIndex);
            [[QPMusicPlayerController sharedMusicPlayer] switchSongFromIndex:mess.firstIndex to:mess.secondIndex];
        }
        else if (mess.message == MusicPacketRequest) {
            Song *streamSong = [self findSong:mess.song];
            
            if (streamSong && [streamSong isMemberOfClass:[LocalSong class]]) {
                NSData *data;
                do {
                    data = [((LocalSong*)streamSong) getNextPacketofMaxBytes:mess.firstIndex];
                    NSLog(@"Getting next packet for bytes request: %ld\n", (long)mess.firstIndex);
                    if (data) {
                        NSLog(@"Got some data to send\n");
                        [self sendMusicData:streamSong withData:data to:peerID];
                        mess.firstIndex -= data.length;
                    }
                } while (data != nil && mess.firstIndex >= 0);
                
                if (((LocalSong*)streamSong).isFinishedSendingSong) {
                    [self finishedStreamingSong:streamSong to:peerID];
                }
                
            }
        }
        else if (mess.message == MusicPacket) {
            Song *streamSong = [self findSong:mess.song];
            if (streamSong && [streamSong isMemberOfClass:[RemoteSong class]]) {
                NSLog(@"Got %lu music bytes in a packet\n", (unsigned long)mess.data.length);
                [((RemoteSong*)streamSong) submitBytes:mess.data];
            }
        }
        else if (mess.message == FinishedStreaming) {
            [[QPMusicPlayerController sharedMusicPlayer] skip];
        }
        else if (mess.message == CurrentTime) {
            [[QPMusicPlayerController sharedMusicPlayer] currentTime:mess.firstIndex];
        }
        else if (mess.message == Booted) {
            NSLog(@"I just got booted");
            [self restartSession];
        }
    });
}

- (Song*)findSong:(Song*)song
{
    if ([[[QPMusicPlayerController sharedMusicPlayer] currentSong] isEqual:song]) {
        return [[QPMusicPlayerController sharedMusicPlayer] currentSong];
    }
    
    for (Song *songFromList in [[QPMusicPlayerController sharedMusicPlayer] playlist]) {
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
    if ([peerID isEqual:self.server] == NO) {
        [self willChangeValueForKey:@"peerArray"];
        [_peerArray addObject:peerID];
        [self didChangeValueForKey:@"peerArray"];
    }
}

-(void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"Removed Peer: %@", peerID.displayName);
    [self willChangeValueForKey:@"peerArray"];
    [_peerArray removeObjectIdenticalTo:peerID];
    [self didChangeValueForKey:@"peerArray"];
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
    for (MCPeerID *peer in mainSession.connectedPeers) {
        NSLog(@"Sending to %@", peer.displayName);
    }
    //NSLog(@"This is the main Thread: %@\n", [NSThread isMainThread] ? @"YES" : @"NO");
}

- (void)sendDataUnreliablyToAllPeers:(NSData*)data
{
    [mainSession sendData:data toPeers:mainSession.connectedPeers withMode:MCSessionSendDataUnreliable error:nil];
}

- (void)nextSong:(Song*)song
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = SkipSong;
    message.song = song;
    [self sendDataToAllPeers:[NSKeyedArchiver archivedDataWithRootObject:message]];
}

- (void)nextSong:(Song*)song forPeer:(MCPeerID*)peer
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = SkipSong;
    message.song = song;
    [self sendData:[NSKeyedArchiver archivedDataWithRootObject:message] ToPeer:peer];
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
    if (song != nil) {
        SingleMessage *message = [[SingleMessage alloc] init];
        message.message = AddSong;
        message.song = song;
        [self sendData:[NSKeyedArchiver archivedDataWithRootObject:message] ToPeer:peer];
    }
}

- (void)addSongToAllPeers:(Song*)song
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = AddSong;
    message.song = song;
    [self sendDataToAllPeers:[NSKeyedArchiver archivedDataWithRootObject:message]];
}

- (void)removeSongFromAllPeersAtIndex:(NSUInteger)ndx
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = RemoveSong;
    message.firstIndex = ndx;
    [self sendDataToAllPeers:[NSKeyedArchiver archivedDataWithRootObject:message]];
}

- (void)switchSongFrom:(NSUInteger)x to:(NSUInteger)y
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = SwitchSong;
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
}

- (void)requestMusicDataForSong:(RemoteSong*)song withAvailableBytes:(NSInteger)bytes
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = MusicPacketRequest;
    message.song = song;
    message.firstIndex = bytes;
    [self sendData:[NSKeyedArchiver archivedDataWithRootObject:message] ToPeer:song.peer];
}

- (void)sendMusicData:(Song*)song withData:(NSData*)data to:(MCPeerID*)peer
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = MusicPacket;
    message.song = song;
    message.data = data;
    [self sendData:[NSKeyedArchiver archivedDataWithRootObject:message] ToPeer:peer];
}

- (void)finishedStreamingSong:(Song*)song to:(MCPeerID*)peer
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = FinishedStreaming;
    message.song = song;
    [self sendData:[NSKeyedArchiver archivedDataWithRootObject:message] ToPeer:peer];
}

- (void)bootPeer:(MCPeerID*)peer
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = Booted;
    [self sendData:[NSKeyedArchiver archivedDataWithRootObject:message] ToPeer:peer];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([keyPath isEqualToString:@"currentSong"]) {
            [self nextSong:[QPMusicPlayerController sharedMusicPlayer].currentSong];
        }
        else if ([keyPath isEqualToString:@"currentSongTime"]) {
            SingleMessage *mess = [[SingleMessage alloc] init];
            mess.message = CurrentTime;
            mess.firstIndex = [[QPMusicPlayerController sharedMusicPlayer] currentSongTime].location;
            [self sendDataUnreliablyToAllPeers:[NSKeyedArchiver archivedDataWithRootObject:mess]];
        }
    });
}

@end
