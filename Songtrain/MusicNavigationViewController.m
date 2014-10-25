//
//  MusicNavigationViewController.m
//  SongTrain
//
//  Created by Brandon on 5/26/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "MusicNavigationViewController.h"

@interface MusicNavigationViewController ()

@end

@implementation MusicNavigationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.navigationBar.tintColor = UIColorFromRGBWithAlpha(0x7FA8D7, 1.0);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(id)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        self.navigationBar.barTintColor = [UIColor darkGrayColor];
        self.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:UIColorFromRGBWithAlpha(0xebebeb, 1.0), NSForegroundColorAttributeName, nil];
    }
    return self;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
