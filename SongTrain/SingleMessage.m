//
//  CommunicationProtocol.m
//  SongTrain
//
//  Created by Quinton Petty on 2/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "SingleMessage.h"

@implementation SingleMessage

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super init])
    {
        self.message = [aDecoder decodeIntForKey:@"message"];
        self.song = [aDecoder decodeObjectForKey:@"song"];
        
        if (self.message == RemoveSong) {
            self.firstIndex = [aDecoder decodeIntForKey:@"1ndx"];
        }
        else if (self.message == SwitchSong) {
            self.firstIndex = [aDecoder decodeIntForKey:@"1ndx"];
            self.secondIndex = [aDecoder decodeIntForKey:@"2ndx"];
        }
        else if (self.message == AlbumImage) {
            self.data = [aDecoder decodeObjectForKey:@"data"];
        }
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.message forKey:@"message"];
    [aCoder encodeObject:self.song forKey:@"song"];
    
    if (self.message == RemoveSong) {
        [aCoder encodeInteger:self.firstIndex forKey:@"1ndx"];
    }
    else if (self.message == SwitchSong) {
        [aCoder encodeInteger:self.firstIndex forKey:@"1ndx"];
        [aCoder encodeInteger:self.secondIndex forKey:@"2ndx"];
    }
    else if (self.message == AlbumImage) {
        [aCoder encodeObject:self.data forKey:@"data"];
    }
}


@end
