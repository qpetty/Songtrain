//
//  Song.m
//  SongTrain
//
//  Created by Quinton Petty on 1/28/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "Song.h"

@implementation Song

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super init])
    {
        self.title = [aDecoder decodeObjectForKey:@"title"];
        self.artistName = [aDecoder decodeObjectForKey:@"name"];
        self.albumImage = [aDecoder decodeObjectForKey:@"image"];
        self.host = [aDecoder decodeObjectForKey:@"host"];
        self.media = [aDecoder decodeObjectForKey:@"media"];
        self.url = [aDecoder decodeObjectForKey:@"url"];
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
}

@end
