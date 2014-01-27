//
//  UsefulFunctions.h
//  SongTrain
//
//  Created by Quinton Petty on 1/24/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#ifndef SongTrain_UsefulFunctions_h
#define SongTrain_UsefulFunctions_h

#ifndef HEX_COLOR
#define HEX_COLOR
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#endif

#define ARTWORK_HEIGHT 138.0

#endif