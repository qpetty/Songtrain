//
//  ServerControlPanel.h
//  SongTrain
//
//  Created by Brandon on 6/6/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "ControlPanel.h"

#define LABEL_SIZE 100
#define LABEL_HEIGHT 30

@interface ServerControlPanel : ControlPanel {
    UILabel *topLabel, *bottomLabel;
    UIButton *playButton;
    UIButton *skipButton;
}

@end
