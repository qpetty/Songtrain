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
         outputASBD = malloc(sizeof(AudioStreamBasicDescription));
         inputASBD = malloc(sizeof(AudioStreamBasicDescription));
     }
    return self;
}

- (instancetype)initWithOutputASBD:(AudioStreamBasicDescription)audioStreanBasicDescription
{
    if(self = [self init])
    {
        memcpy(outputASBD, &audioStreanBasicDescription, sizeof(AudioStreamBasicDescription));
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
        self.url = [aDecoder decodeObjectForKey:@"url"];
        
        _songLength = [aDecoder decodeIntForKey:@"songLength"];
        
        NSUInteger size;
        void *temp = (AudioStreamBasicDescription*)[aDecoder decodeBytesForKey:@"asbd" returnedLength:&size];
        memcpy(outputASBD, temp, sizeof(AudioStreamBasicDescription));
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.title forKey:@"title"];
    [aCoder encodeObject:self.artistName forKey:@"name"];
    [aCoder encodeObject:self.albumImage forKey:@"image"];
    [aCoder encodeObject:self.url forKey:@"url"];
    
    [aCoder encodeInt:_songLength forKey:@"songLength"];
    
    [aCoder encodeBytes:(const uint8_t*)outputASBD length:sizeof(AudioStreamBasicDescription) forKey:@"asbd"];
}

- (int)getMusicPackets:(UInt32*)numOfPackets forBuffer:(AudioBufferList*)ioData
{
    return -1;
}

- (void)dealloc
{
    if (outputASBD){
        free(outputASBD);
        outputASBD = NULL;
    }
    if (inputASBD){
        free(inputASBD);
        inputASBD = NULL;
    }
}

@end
