//
//  ServerPlaylistViewController.h
//  SongTrain
//
//  Created by Quinton Petty on 2/2/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlaylistViewController.h"
#import "TDAudioStreamer.h"

@interface ServerPlaylistViewController : PlaylistViewController <MCNearbyServiceAdvertiserDelegate, AVAudioPlayerDelegate, SongtrainProtocolDelegate, TDAudioInputStreamDelegate>{
    MCNearbyServiceAdvertiser *advert;
    TDAudioInputStreamer *audioInStream;
    AVAudioPlayer *audioPlayer;
    
    UIButton *playButton, *skipButton;
}

@end
