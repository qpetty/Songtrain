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
     }
    return self;
}

- (instancetype)initWithMediaItem:(MPMediaItem*)item
{
    if(self = [self init])
    {
        self.title = [item valueForProperty:MPMediaItemPropertyTitle];
        self.artistName = [item valueForProperty:MPMediaItemPropertyArtist];
        self.url = [item valueForProperty:MPMediaItemPropertyAssetURL];
        self.songLength = [[item valueForProperty:MPMediaItemPropertyPlaybackDuration] intValue];
        self.persistantID = [item valueForProperty:MPMediaItemPropertyPersistentID];
        
        _assetURL = [AVURLAsset URLAssetWithURL:self.url options:nil];
        
        CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)[[[_assetURL.tracks objectAtIndex:0] formatDescriptions] objectAtIndex:0];
        const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription (item);
        /*
        NSLog(@"ASBD sample rate: %f", asbd->mSampleRate);
        NSLog(@"ASBD format id: %d", asbd->mFormatID);
        NSLog(@"ASBD format flags: %d", asbd->mFormatFlags);
        NSLog(@"ASBD frames per packet: %d", asbd->mFramesPerPacket);
        NSLog(@"ASBD channels per frame: %d", asbd->mChannelsPerFrame);
        NSLog(@"ASBD bits per channel: %d", asbd->mBitsPerChannel);
        NSLog(@"ASBD bytes per packet: %d", asbd->mBytesPerPacket);
        NSLog(@"ASBD bytes per frame: %d", asbd->mBytesPerFrame);
        */
        memcpy(_inputASBD, asbd, sizeof(AudioStreamBasicDescription));
    }
    return self;
}

- (instancetype)initWithItem:(MPMediaItem*)item andOutputASBD:(AudioStreamBasicDescription)audioStreanBasicDescription
{
    if(self = [self initWithMediaItem:item])
    {
        memcpy(outputASBD, &audioStreanBasicDescription, sizeof(AudioStreamBasicDescription));
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
        self.songLength = song.songLength;
        
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
        //self.albumImage = [aDecoder decodeObjectForKey:@"image"];
        self.persistantID = [aDecoder decodeObjectForKey:@"id"];
        self.url = [aDecoder decodeObjectForKey:@"url"];
        
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
    //[aCoder encodeObject:self.albumImage forKey:@"image"];
    [aCoder encodeObject:self.persistantID forKey:@"id"];
    [aCoder encodeObject:self.url forKey:@"url"];
    
    [aCoder encodeInt:_songLength forKey:@"songLength"];
    
    [aCoder encodeBytes:(const uint8_t*)outputASBD length:sizeof(AudioStreamBasicDescription) forKey:@"out"];
    [aCoder encodeBytes:(const uint8_t*)_inputASBD length:sizeof(AudioStreamBasicDescription) forKey:@"in"];
}

- (int)getMusicPackets:(UInt32*)numOfPackets forBuffer:(AudioBufferList*)ioData
{
    return -1;
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
}

@end
