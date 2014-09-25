//
//  NearbyTrainViewController.m
//  Songtrain
//
//  Created by Quinton Petty on 9/24/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "NearbyTrainViewController.h"
#import "QPSessionManager.h"

@interface NearbyTrainViewController ()

@end

@implementation NearbyTrainViewController {
    QPSessionManager *sessionManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    sessionManager = [QPSessionManager sessionManager];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"TrainCellView" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"TrainCell"];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [sessionManager addObserver:self forKeyPath:@"peerArray" options:NSKeyValueObservingOptionNew context:nil];
    [sessionManager startBrowsingForTrains];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [sessionManager stopBrowsingForTrains];
    [sessionManager removeObserver:self forKeyPath:@"peerArray"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"peerArray"]) {
        [self.tableView reloadData];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return sessionManager.peerArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TrainCell" forIndexPath:indexPath];
    
    MCPeerID *peerID = [sessionManager.peerArray objectAtIndex:indexPath.row];
    cell.textLabel.text = peerID.displayName;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [sessionManager connectToPeer:[sessionManager.peerArray objectAtIndex:indexPath.row]];
    [self.mainViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
