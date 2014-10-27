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
        
        if (self.message == AddSong) {
            self.song = [aDecoder decodeObjectForKey:@"song"];
        }
        else if (self.message == RemoveSong) {
            self.firstIndex = [aDecoder decodeIntForKey:@"1ndx"];
        }
        else if (self.message == SwitchSong) {
            self.firstIndex = [aDecoder decodeIntForKey:@"1ndx"];
            self.secondIndex = [aDecoder decodeIntForKey:@"2ndx"];
        }
        else if (self.message == SkipSong) {
            self.song = [aDecoder decodeObjectForKey:@"song"];
        }
        else if (self.message == AlbumRequest) {
            self.song = [aDecoder decodeObjectForKey:@"song"];
        }
        else if (self.message == AlbumImage) {
            self.song = [aDecoder decodeObjectForKey:@"song"];
            self.data = [aDecoder decodeObjectForKey:@"data"];
        }
        else if (self.message == PrepareSong) {
            self.song = [aDecoder decodeObjectForKey:@"song"];
        }
        else if (self.message == MusicPacketRequest) {
            self.song = [aDecoder decodeObjectForKey:@"song"];
            self.firstIndex =[aDecoder decodeIntForKey:@"1ndx"];
        }
        else if (self.message == MusicPacket) {
            self.song = [aDecoder decodeObjectForKey:@"song"];
            self.data = [aDecoder decodeObjectForKey:@"data"];
        }
        else if (self.message == FinishedStreaming) {
            self.song = [aDecoder decodeObjectForKey:@"song"];
        }
        else if (self.message == CurrentTime) {
            self.firstIndex =[aDecoder decodeIntForKey:@"1ndx"];
        }
        else if (self.message == CurrentSong) {
            self.song = [aDecoder decodeObjectForKey:@"song"];
        }
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.message forKey:@"message"];
    
    
    if (self.message == AddSong) {
        [aCoder encodeObject:self.song forKey:@"song"];
    }
    else if (self.message == RemoveSong) {
        [aCoder encodeInteger:self.firstIndex forKey:@"1ndx"];
    }
    else if (self.message == SwitchSong) {
        [aCoder encodeInteger:self.firstIndex forKey:@"1ndx"];
        [aCoder encodeInteger:self.secondIndex forKey:@"2ndx"];
    }
    else if (self.message == SkipSong) {
        [aCoder encodeObject:self.song forKey:@"song"];
    }
    else if (self.message == AlbumRequest) {
        [aCoder encodeObject:self.song forKey:@"song"];
    }
    else if (self.message == AlbumImage) {
        [aCoder encodeObject:self.song forKey:@"song"];
        [aCoder encodeObject:self.data forKey:@"data"];
    }
    else if (self.message == PrepareSong) {
        [aCoder encodeObject:self.song forKey:@"song"];
    }
    else if (self.message == MusicPacketRequest) {
        [aCoder encodeObject:self.song forKey:@"song"];
        [aCoder encodeInteger:self.firstIndex forKey:@"1ndx"];
    }
    else if (self.message == MusicPacket) {
        [aCoder encodeObject:self.song forKey:@"song"];
        [aCoder encodeObject:self.data forKey:@"data"];
    }
    else if (self.message == FinishedStreaming) {
        [aCoder encodeObject:self.song forKey:@"song"];
    }
    else if (self.message == CurrentTime) {
        [aCoder encodeInteger:self.firstIndex forKey:@"1ndx"];
    }
    else if (self.message == CurrentSong) {
        [aCoder encodeObject:self.song forKey:@"song"];
    }
}


@end
