//
//  Song.m
//  SongTrain
//
//  Created by Quinton Petty on 1/28/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "Song.h"

@implementation Song

-(instancetype)init
{
     if(self = [super init])
     {
         _asbd = malloc(sizeof(AudioStreamBasicDescription));
     }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [self init])
    {
        self.title = [aDecoder decodeObjectForKey:@"title"];
        self.artistName = [aDecoder decodeObjectForKey:@"name"];
        self.albumImage = [aDecoder decodeObjectForKey:@"image"];
        self.host = [aDecoder decodeObjectForKey:@"host"];
        self.media = [aDecoder decodeObjectForKey:@"media"];
        self.url = [aDecoder decodeObjectForKey:@"url"];
        
        NSUInteger size;
        void *temp = (AudioStreamBasicDescription*)[aDecoder decodeBytesForKey:@"asbd" returnedLength:&size];
        memcpy(_asbd, temp, sizeof(AudioStreamBasicDescription));
        
        _songPosition = [aDecoder decodeIntForKey:@"songPosition"];
        _totalSongs = [aDecoder decodeIntForKey:@"totalSongs"];
        
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.title forKey:@"title"];
    [aCoder encodeObject:self.artistName forKey:@"name"];
    [aCoder encodeObject:self.albumImage forKey:@"image"];
    [aCoder encodeObject:self.host forKey:@"host"];
    [aCoder encodeObject:self.media forKey:@"media"];
    [aCoder encodeObject:self.url forKey:@"url"];
    [aCoder encodeInt:_songPosition forKey:@"songPosition"];
    [aCoder encodeInt:_totalSongs forKey:@"totalSongs"];
    
    [aCoder encodeBytes:(const uint8_t*)_asbd length:sizeof(AudioStreamBasicDescription) forKey:@"asbd"];
}

- (void)dealloc
{
    if (_asbd){
        free(_asbd);
        _asbd = NULL;
    }
}

@end
