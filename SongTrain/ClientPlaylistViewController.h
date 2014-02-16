//
//  ClientPlaylistViewController.h
//  SongTrain
//
//  Created by Quinton Petty on 2/2/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlaylistViewController.h"

@interface ClientPlaylistViewController : PlaylistViewController {
    TDAudioOutputStreamer *audioOutStream;
}

@end
