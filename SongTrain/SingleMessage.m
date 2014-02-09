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
        _message = [aDecoder decodeIntForKey:@"message"];
        self.data = [aDecoder decodeObjectForKey:@"data"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:_message forKey:@"message"];
    [aCoder encodeObject:self.data forKey:@"data"];
}


@end
