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

@interface Song : NSObject <NSCoding>{
    AudioStreamBasicDescription *outputASBD;
    UIImage *image;
}

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *artistName;
@property (strong, nonatomic, getter=getAlbumImage) UIImage *albumImage;
@property (strong, nonatomic) NSNumber *persistantID;
@property (strong, nonatomic) NSURL *url;

@property (nonatomic) AudioStreamBasicDescription *inputASBD;
@property (nonatomic) int songLength;

- (instancetype)initWithTitle:(NSString*)title andArtist:(NSString*)artist;
- (instancetype)initWithSong:(Song*)song andOutputASBD:(AudioStreamBasicDescription)audioStreanBasicDescription;

- (int)getMusicPackets:(UInt32*)numOfPackets forBuffer:(AudioBufferList*)ioData;
- (void)prepareSong;
- (void)cleanUpSong;
@end
