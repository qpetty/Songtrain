//
//  CommunicationProtocol.h
//  SongTrain
//
//  Created by Quinton Petty on 2/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SingleMessage : NSObject

@property (nonatomic) NSInteger message;
@property (strong, nonatomic) NSData *data;

@end
