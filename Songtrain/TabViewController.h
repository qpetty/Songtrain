//
//  TabViewController.h
//  SongTrain
//
//  Created by Quinton Petty on 4/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@protocol TabViewControllerDelegate <NSObject>

- (void)addItem:(MPMediaItem*)item;
- (void)removeItem:(MPMediaItem*)item;
- (BOOL)isItemSelected:(MPMediaItem*)item;
- (void)addButton:(UIBarButtonItem*)button;
- (void)removeButton:(UIBarButtonItem*)button;
- (void)done;

@end

@interface TabViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>{
    NSArray *displayItems;
    MPMediaQuery *query;
}

@property (weak, nonatomic) id <TabViewControllerDelegate> delegate;

@end
