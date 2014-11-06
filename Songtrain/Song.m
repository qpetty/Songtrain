//
//  Song.m
//  SongTrain
//
//  Created by Quinton Petty on 1/28/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "Song.h"

@implementation Song

- (instancetype)init
{
     if(self = [super init])
     {
         outputASBD = malloc(sizeof(AudioStreamBasicDescription));
         _inputASBD = malloc(sizeof(AudioStreamBasicDescription));
         image = nil;
         self.inputASDBIsSet = NO;
         self.isFinishedSendingSong = NO;
     }
    return self;
}

- (instancetype)initWithTitle:(NSString*)title andArtist:(NSString*)artist {
    if(self = [self init])
    {
        self.title = title;
        self.artistName = artist;
    }
    return self;
}

- (instancetype)initWithSong:(Song*)song andOutputASBD:(AudioStreamBasicDescription)audioStreanBasicDescription
{
    if(self = [self init])
    {
        self.title = song.title;
        self.artistName = song.artistName;
        self.persistantID = song.persistantID;
        self.url = song.url;
        self.musicURL = song.musicURL;
        self.artworkURL = song.artworkURL;
        
        self.songLength = song.songLength;
        self.inputASDBIsSet = song.inputASDBIsSet;
        
        memcpy(outputASBD, &audioStreanBasicDescription, sizeof(AudioStreamBasicDescription));
        memcpy(_inputASBD, song.inputASBD, sizeof(AudioStreamBasicDescription));
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [self init])
    {
        self.title = [aDecoder decodeObjectForKey:@"title"];
        self.artistName = [aDecoder decodeObjectForKey:@"name"];
        self.persistantID = [aDecoder decodeObjectForKey:@"id"];
        self.url = [aDecoder decodeObjectForKey:@"url"];
        self.musicURL = [aDecoder decodeObjectForKey:@"musicURL"];
        self.artworkURL = [aDecoder decodeObjectForKey:@"artworkURL"];
        
        self.inputASDBIsSet = [aDecoder decodeBoolForKey:@"inputASBDset"];
        _songLength = [aDecoder decodeIntForKey:@"songLength"];
        
        NSUInteger size;
        void *temp = (AudioStreamBasicDescription*)[aDecoder decodeBytesForKey:@"out" returnedLength:&size];
        memcpy(outputASBD, temp, sizeof(AudioStreamBasicDescription));
        
        temp = (AudioStreamBasicDescription*)[aDecoder decodeBytesForKey:@"in" returnedLength:&size];
        memcpy(_inputASBD, temp, sizeof(AudioStreamBasicDescription));
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.title forKey:@"title"];
    [aCoder encodeObject:self.artistName forKey:@"name"];
    [aCoder encodeObject:self.persistantID forKey:@"id"];
    [aCoder encodeObject:self.url forKey:@"url"];
    [aCoder encodeObject:self.musicURL forKey:@"musicURL"];
    [aCoder encodeObject:self.artworkURL forKey:@"artworkURL"];
    
    [aCoder encodeBool:self.inputASDBIsSet forKey:@"inputASBDset"];
    [aCoder encodeInt:_songLength forKey:@"songLength"];
    
    [aCoder encodeBytes:(const uint8_t*)outputASBD length:sizeof(AudioStreamBasicDescription) forKey:@"out"];
    [aCoder encodeBytes:(const uint8_t*)_inputASBD length:sizeof(AudioStreamBasicDescription) forKey:@"in"];
}

- (int)getMusicPackets:(UInt32*)numOfPackets forBuffer:(AudioBufferList*)ioData
{
    return -1;
}

-(NSData *)getNextPacketofMaxBytes:(NSInteger)maxBytes {
    return nil;
}

- (BOOL)isEqual:(id)object
{
    if (object == nil)
        return false;
    if (![object isKindOfClass:[Song class]])
        return false;
    
    if (![((Song*)object).url isEqual:self.url])
        return false;
    
    return true;
}

- (void)setAlbumImage:(UIImage *)albumImage
{
    _albumImage = albumImage;
    image = _albumImage;
}

- (void)prepareSong{
}

- (void)cleanUpSong{
}

- (void)dealloc
{
    if (outputASBD){
        free(outputASBD);
        outputASBD = NULL;
    }
    if (_inputASBD){
        free(_inputASBD);
        _inputASBD = NULL;
    }
    image = nil;
}

@end
