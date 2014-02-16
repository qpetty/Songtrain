//
//  QPMusicPlayerController.h
//  SongTrain
//
//  Created by Quinton Petty on 2/10/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "TDAudioStreamer.h"
#import "NSMutableArray+Playlist.h"
#import "QPSessionManager.h"

@protocol QPMusicPlayerControllerDelegate <NSObject>

- (void)playListHasBeenUpdated;

@end

@interface QPMusicPlayerController : NSObject <AVAudioPlayerDelegate, TDAudioInputStreamDelegate>{
    QPSessionManager *sessionManager;
    MCPeerID *pid;
    
    TDAudioInputStreamer *audioInStream;
    TDAudioOutputStreamer *audioOutStream;
    AVAudioPlayer *audioPlayer;
    
    BOOL currentlyPlaying;
}

@property (weak, nonatomic) id <QPMusicPlayerControllerDelegate> delegate;
@property (nonatomic, retain) Song *currentSong;
@property (nonatomic, retain) NSMutableArray *playlist;

+ (id)musicPlayer;

- (void)addSongsToPlaylist:(MPMediaItemCollection*)songs;
- (void)addArrayOfSongsToPlaylist:(NSMutableArray *)songs;
- (void)recievedPlaylistFromServer:(NSMutableArray *)songs;

- (void)resetMusicPlayer;

- (void)removeSongsWithPeerID:(MCPeerID*)peerID;

- (void)recievedStream:(NSInputStream*)inputStream;
- (void)fillOutStream:(NSOutputStream*)outStream FromSong:(Song*)singleSong;
- (void)stopOutStream;

- (void)finishedPlayingSong;
@end
