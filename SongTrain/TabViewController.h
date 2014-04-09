//
//  TabViewController.h
//  SongTrain
//
//  Created by Quinton Petty on 4/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TabViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>{
    NSArray *displayItems;
}

@end
