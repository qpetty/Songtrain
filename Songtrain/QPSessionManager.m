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
    [self willChangeValueForKey:@"connectedPeerArray"];
    [_connectedPeerArray removeAllObjects];
    [self didChangeValueForKey:@"connectedPeerArray"];
    NSLog(@"AVERTISING PEER");
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
    NSLog(@"NOT AVERTISING PEER");
    [advert stopAdvertisingPeer];
    [[QPMusicPlayerController sharedMusicPlayer] resetToClient];
    [browse invitePeer:peerID toSession:mainSession withContext:nil timeout:0];
    
    [self willChangeValueForKey:@"server"];
    _server = peerID;
    [self didChangeValueForKey:@"server"];
    
    [self willChangeValueForKey:@"connectedPeerArray"];
    [_connectedPeerArray removeAllObjects];
    [self didChangeValueForKey:@"connectedPeerArray"];
    
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
        [self.sessionDelegate connectedToPeer:peerID];
        
        if ([self.pid isEqual:self.server]) {
            NSLog(@"Giving songs to %@", peerID.displayName);
            [self sendCurrentSong:[QPMusicPlayerController sharedMusicPlayer].currentSong toPeer:peerID];
            for (Song *s in [QPMusicPlayerController sharedMusicPlayer].playlist) {
                [self addSong:s toPeer:peerID];
            }
        }
    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"Disconnected from %@", peerID.displayName);
        NSUInteger ndx = [_connectedPeerArray indexOfObject:peerID];
        if (ndx != NSNotFound) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self removeSongsFromPeer:peerID];
                [self willChangeValueForKey:@"connectedPeerArray"];
                [_connectedPeerArray removeObjectIdenticalTo:peerID];
                [self didChangeValueForKey:@"connectedPeerArray"];
                [self.sessionDelegate disconnectedFromPeer:peerID atIndex:ndx];
            });
        }
        
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
    SingleMessage *mess = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (mess.message == AlbumRequest) {
             NSLog(@"Sending artwork for %@ to %@", mess.song.title, peerID.displayName);
            [self sendAlbumArtwork:[self findSong:mess.song] to:peerID];
        }
        else if (mess.message == AlbumImage) {
            NSLog(@"Got artwork for %@ from %@", mess.song.title, peerID.displayName);
            [self findSong:mess.song].albumImage = [NSKeyedUnarchiver unarchiveObjectWithData:mess.data];
            [[QPMusicPlayerController sharedMusicPlayer] updateNowPlaying];
        }
        else if (mess.message == AddSong && _currentRole == ServerConnection) {
            NSLog(@"Requesting to add %@ to playlist from %@", mess.song.title, peerID.displayName);
            //RemoteSong *newSong = [[RemoteSong alloc] initWithSong:mess.song ofType:MusicPlayerSong fromPeer:peerID andOutputASBD:*([QPMusicPlayerController sharedMusicPlayer].audioFormat)];
            Song *newSong = [self makeSongFromReceivedSong:mess.song fromPeer:peerID];
            [[QPMusicPlayerController sharedMusicPlayer] addSongToPlaylist:newSong];
            [self addSongToAllPeers:newSong];
        }
        else if (mess.message == AddSong && _currentRole == ClientConnection) {
            NSLog(@"Adding %@ to playlist", mess.song.title);
            [[QPMusicPlayerController sharedMusicPlayer] addSongToPlaylist:[self makeSongFromReceivedSong:mess.song fromPeer:peerID]];
        }
        else if (mess.message == SkipSong && _currentRole == ClientConnection) {
            NSLog(@"Skip song");
            [[QPMusicPlayerController sharedMusicPlayer] nextSong];
        }
        else if (mess.message == RemoveSong && _currentRole == ClientConnection) {
            NSLog(@"Remove song at index: %ld, from %@\n", (long)mess.firstIndex, peerID.displayName);
            [[QPMusicPlayerController sharedMusicPlayer] removeSongFromPlaylist:mess.firstIndex];
        }
        else if (mess.message == SwitchSong && _currentRole == ClientConnection) {
            NSLog(@"Switched index %ld with %ld, from %@\n", (long)mess.firstIndex, (long)mess.secondIndex, peerID.displayName);
            [[QPMusicPlayerController sharedMusicPlayer] switchSongFromIndex:mess.firstIndex to:mess.secondIndex];
        }
        else if (mess.message == PrepareSong) {
            [[self findSong:mess.song] prepareSong];
        }
        else if (mess.message == MusicPacketRequest) {
            Song *streamSong = [self findSong:mess.song];
            
            if (streamSong && [streamSong isMemberOfClass:[RemoteSong class]] == NO) {
                NSData *data;
                
                if (streamSong.inputASDBIsSet == NO && mess.song.inputASDBIsSet == YES) {
                    NSLog(@"Just set %@'s inputASBD", streamSong.title);
                    memcpy(streamSong.inputASBD, mess.song.inputASBD, sizeof(AudioStreamBasicDescription));
                    streamSong.inputASDBIsSet = YES;
                }
                
                do {
                    data = [streamSong getNextPacketofMaxBytes:mess.firstIndex];
                    NSLog(@"Getting next packet for bytes request: %ld\n", (long)mess.firstIndex);
                    if (data) {
                        NSLog(@"Got some data to send\n");
                        [self sendMusicData:streamSong withData:data to:peerID];
                        mess.firstIndex -= data.length;
                    }
                } while (data != nil && mess.firstIndex >= 0);
                
                if (streamSong.isFinishedSendingSong) {
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
            NSLog(@"Finished streaming from %@\n", peerID.displayName);
            [[QPMusicPlayerController sharedMusicPlayer] skip];
        }
        else if (mess.message == CurrentTime) {
            NSLog(@"Got current time, %ld, from %@\n", (long)mess.firstIndex, peerID.displayName);
            [[QPMusicPlayerController sharedMusicPlayer] currentTime:mess.firstIndex];
        }
        else if (mess.message == CurrentSong) {
            NSLog(@"Got current song from %@\n", peerID.displayName);
            [[QPMusicPlayerController sharedMusicPlayer] updateCurrentSong:[self makeSongFromReceivedSong:mess.song fromPeer:peerID]];
        }
        else if (mess.message == Booted) {
            NSLog(@"%@:I just got booted :(", self.pid.displayName);
            [self restartSession];
        }
        else {
            NSLog(@"Got some unknown data from %@\n", peerID.displayName);
        }
    });
}

- (Song*)makeSongFromReceivedSong:(Song*)song fromPeer:(MCPeerID*)peerID {
    Song *newSong;
    
    if (song == nil) {
        return nil;
    }
    
    if ([song isMemberOfClass:[RemoteSong class]] && [((RemoteSong*)song).peer isEqual:self.pid]) {
        NSLog(@"Class: %@", [song class]);
        if (((RemoteSong*)song).type == MusicPlayerSong) {
            NSLog(@"make regular song");
            newSong = [[LocalSong alloc] initLocalSongFromSong:song WithOutputASBD:*([QPMusicPlayerController sharedMusicPlayer].audioFormat)];
        } else if (((RemoteSong*)song).type == SoundCloud) {
            NSLog(@"make soundcloud song");
            newSong = [[SoundCloudSong alloc] initWithSong:song];
        } else {
            NSLog(@"didnt make any song");
        }

    }
    else if ([song isMemberOfClass:[RemoteSong class]] == NO) {
        RemoteSongType songType;
        if ([song isMemberOfClass:[LocalSong class]]) {
            songType = MusicPlayerSong;
        } else if ([song isMemberOfClass:[SoundCloudSong class]]) {
            songType = SoundCloud;
        }
        
        newSong = [[RemoteSong alloc] initWithSong:song ofType:songType fromPeer:peerID andOutputASBD:*([QPMusicPlayerController sharedMusicPlayer].audioFormat)];
    }
    else {
        newSong = song;
    }
    
    return newSong;
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
    NSLog(@"Found %@", peerID.displayName);
    [self willChangeValueForKey:@"peerArray"];
    [_peerArray addObject:peerID];
    [self didChangeValueForKey:@"peerArray"];
    [self.browsingDelegate foundPeer:peerID];
}

-(void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSUInteger ndx = [_peerArray indexOfObject:peerID];
    [self willChangeValueForKey:@"peerArray"];
    [_peerArray removeObjectIdenticalTo:peerID];
    [self didChangeValueForKey:@"peerArray"];
    [self.browsingDelegate lostPeer:peerID atIndex:ndx];
}

#pragma mark - Data Methods

- (void)sendData:(NSData*)data ToPeer:(MCPeerID*)peerID
{
    //NSLog(@"Sending Data to %@\n", peerID.displayName);
    
    NSError *error;
    [mainSession sendData:data toPeers:[NSArray arrayWithObject:peerID] withMode:MCSessionSendDataReliable error:&error];
    
    if (error != nil) {
        SingleMessage *mess = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSLog(@"Tried to send message of type %ld to %@", (long)mess.message, peerID.displayName);
        NSLog(@"Error: %@\n", error.localizedDescription);
    }
}

- (void)sendDataToAllPeers:(NSData*)data
{
    if (mainSession.connectedPeers.count == 0) {
        NSLog(@"No one to send a message to :(");
        return;
    }
    
    NSError *error;
    [mainSession sendData:data toPeers:mainSession.connectedPeers withMode:MCSessionSendDataReliable error:&error];
    if (error != nil) {
        SingleMessage *mess = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSLog(@"Tried to send message of type %ld to everyone", (long)mess.message);
        NSLog(@"Error: %@\n", error.localizedDescription);
    }
    
    /*
    for (MCPeerID *peer in mainSession.connectedPeers) {
        NSLog(@"Sending to %@", peer.displayName);
    }
     */
    //NSLog(@"This is the main Thread: %@\n", [NSThread isMainThread] ? @"YES" : @"NO");
}

- (void)sendDataUnreliablyToAllPeers:(NSData*)data
{
    if (mainSession.connectedPeers.count == 0) {
        //NSLog(@"No one to send a message to :(");
        return;
    }
    
    NSError *error;
    [mainSession sendData:data toPeers:mainSession.connectedPeers withMode:MCSessionSendDataUnreliable error:&error];
    
    if (error != nil) {
        SingleMessage *mess = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSLog(@"Tried to send message unreliably of type %ld to everyone", (long)mess.message);
        NSLog(@"Error: %@\n", error.localizedDescription);
    }
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
    NSLog(@"I'd like some artwork for %@ from %@", song.title, song.peer.displayName);
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

- (void)prepareRemoteSong:(RemoteSong*)song
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = PrepareSong;
    message.song = song;
    [self sendData:[NSKeyedArchiver archivedDataWithRootObject:message] ToPeer:song.peer];
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

- (void)sendCurrentSong:(Song*)song toPeer:(MCPeerID*)peer
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = CurrentSong;
    message.song = song;
    [self sendData:[NSKeyedArchiver archivedDataWithRootObject:message] ToPeer:peer];
}

- (void)bootPeer:(MCPeerID*)peer
{
    SingleMessage *message = [[SingleMessage alloc] init];
    message.message = Booted;
    [self sendData:[NSKeyedArchiver archivedDataWithRootObject:message] ToPeer:peer];
    
    [self removeSongsFromPeer:peer];
}

-(void)removeSongsFromPeer:(MCPeerID*)peer {
    NSMutableIndexSet *songsToRemove = [[NSMutableIndexSet alloc] init];
    
    [[QPMusicPlayerController sharedMusicPlayer].playlist enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isMemberOfClass:[RemoteSong class]] && [((RemoteSong*)obj).peer isEqual:peer]) {
            [songsToRemove addIndex:idx];
        }
    }];
    
    [[QPMusicPlayerController sharedMusicPlayer] removeSongIndexesFromPlaylist:songsToRemove];
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
