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
        self.host = [aDecoder decodeObjectForKey:@"host"];
        self.media = [aDecoder decodeObjectForKey:@"media"];
        _songPosition = [aDecoder decodeIntForKey:@"songPosition"];
        _totalSongs = [aDecoder decodeIntForKey:@"totalSongs"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.title forKey:@"title"];
    [aCoder encodeObject:self.artistName forKey:@"name"];
    [aCoder encodeObject:self.host forKey:@"host"];
    [aCoder encodeObject:self.media forKey:@"media"];
    [aCoder encodeInt:_songPosition forKey:@"songPosition"];
    [aCoder encodeInt:_totalSongs forKey:@"totalSongs"];
}

@end
