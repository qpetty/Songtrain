//
//  Song.h
//  SongTrain
//
//  Created by Quinton Petty on 1/28/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AVFoundation/AVFoundation.h>

static const int kBufferLength = 32768 * 32;

@interface Song : NSObject <NSCoding>{
    AudioStreamBasicDescription *outputASBD;
    UIImage *image;
}

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *artistName;
@property (strong, nonatomic, getter=getAlbumImage, setter=setAlbumImage:) UIImage *albumImage;
@property MCPeerID *peer;
@property (readonly, getter=isRemoteSong) BOOL remoteSong;

@property (strong, nonatomic) NSURL *url;

@property (nonatomic) BOOL isFinishedSendingSong;
@property (nonatomic) BOOL inputASDBIsSet;
@property (nonatomic) AudioStreamBasicDescription *inputASBD;
@property (nonatomic) int songLength;

- (instancetype)initWithTitle:(NSString*)title andArtist:(NSString*)artist andPeer:(MCPeerID*)peer;

- (int)getMusicPackets:(UInt32*)numOfPackets forBuffer:(AudioBufferList*)ioData;
- (NSData *)getNextPacketofMaxBytes:(NSInteger)maxBytes;
- (void)submitBytes:(NSData*)bytes;

- (void)prepareSong;
- (void)cleanUpSong;
@end
