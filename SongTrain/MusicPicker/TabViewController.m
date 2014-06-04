//
//  TabViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 4/8/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "TabViewController.h"
#import <CoreImage/CoreImage.h>

@interface TabViewController () {
    UITableView *wholeTableView;
}

@end

@implementation TabViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (UIImage *)applyBlurOnImage: (UIImage *)imageToBlur withRadius: (CGFloat)blurRadius {
    
    CIImage *originalImage = [CIImage imageWithCGImage: imageToBlur.CGImage];
    CIFilter *filter = [CIFilter filterWithName: @"CIGaussianBlur" keysAndValues: kCIInputImageKey, originalImage, @"inputRadius", @(blurRadius), nil];
    CIImage *outputImage = filter.outputImage;
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef outImage = [context createCGImage: outputImage fromRect: [outputImage extent]]; return [UIImage imageWithCGImage: outImage];
}

-(id)init
{
    self = [super init];
    if (self) {
        wholeTableView = [[UITableView alloc] init];
        wholeTableView.dataSource = self;
        wholeTableView.delegate = self;
        
        //UIImage *blurredImage = [self applyBlurOnImage:[UIImage imageNamed:@"splash.png"] withRadius:1];
        UIImage *blurredImage = [UIImage imageNamed:@"splash.png"];
        wholeTableView.backgroundView = [[UIImageView alloc] initWithImage:blurredImage];
        wholeTableView.backgroundColor = UIColorFromRGBWithAlpha(0x4E5257, 0.3);
        wholeTableView.sectionIndexBackgroundColor = [UIColor clearColor];
        [wholeTableView setBackgroundColor: [UIColor clearColor]];
        
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:wholeTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [wholeTableView reloadData];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    wholeTableView.frame = CGRectMake(self.view.frame.origin.x,
                                      self.view.frame.origin.y,
                                      self.view.frame.size.width,
                                      self.view.frame.size.height - 49);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [[query itemSections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[[query itemSections] objectAtIndex:section] range].length;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MusicCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] init];
        [cell setRestorationIdentifier:@"MusicCell"];
    }
    
    cell.backgroundColor = UIColorFromRGBWithAlpha(0x4E5257, 0.3);
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.userInteractionEnabled = YES;
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    return cell;
}

// Changes header views background color
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    view.tintColor = UIColorFromRGB(0xC5D1DE);
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
