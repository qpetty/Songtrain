//
//  ServerPlaylistViewController.h
//  SongTrain
//
//  Created by Quinton Petty on 2/2/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlaylistViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "MusicQueuePlayer.h"

@interface ServerPlaylistViewController : PlaylistViewController <MCNearbyServiceAdvertiserDelegate>{
    MCNearbyServiceAdvertiser *advert;
    MusicQueuePlayer *player;
}

@end
