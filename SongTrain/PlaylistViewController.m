//
//  PlaylistViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 1/26/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "PlaylistViewController.h"

@interface PlaylistViewController ()

@end

@implementation PlaylistViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (instancetype)initWithSession:(MCSession*)session
{
    if (self = [super init]) {
        mainSession = session;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.backgroundColor = UIColorFromRGB(0x363636);
    
    //Create Song View at top of view
    CGRect location = CGRectMake(self.navigationController.navigationBar.bounds.origin.x,
                                 self.navigationController.navigationBar.bounds.origin.y + self.navigationController.navigationBar.bounds.size.height + [[UIApplication sharedApplication]statusBarFrame].size.height,
                                 self.view.bounds.size.width,
                                 ARTWORK_HEIGHT);
    
    albumArtwork = [[CurrentSongView alloc] initWithFrame:location];
    albumArtwork.delegate = self;
    [self.view addSubview:albumArtwork];
    
    playlist = [[NSMutableArray alloc] init];
    
    //Initialize Media picker
    picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    picker.allowsPickingMultipleItems = YES;
    picker.prompt = NSLocalizedString (@"Add songs to play", "Prompt in media item picker");
    
    //Create an Add button
    CGRect buttonLocation = CGRectMake(albumArtwork.frame.origin.x,
                          albumArtwork.frame.origin.y + albumArtwork.frame.size.height,
                          50,
                          30);
    
    addToList = [[UIButton alloc] initWithFrame:buttonLocation];
    [addToList setTitle:@"Add" forState:UIControlStateNormal];
    [addToList addTarget:self action:@selector(addToPlaylist) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:addToList];
    
    //Create TableView
    location = CGRectMake(self.view.bounds.origin.x,
                          location.origin.y + location.size.height + 40,
                          self.view.bounds.size.width,
                          self.view.bounds.size.height - location.origin.y - location.size.height - 40);
    mainTableView = [[GrayTableView alloc] initWithFrame:location];
    mainTableView.delegate = self;
    mainTableView.dataSource = self;
    [self.view addSubview:mainTableView];
    
    mainSession.delegate = self;
    pid = mainSession.myPeerID;
    service = SERVICE_TYPE;
    
    trainProtocol = [[SongtrainProtocol alloc] init];
    trainProtocol.delegate = self;
}

- (void)playbackStateChanged:(id)sender
{
}

- (void)addToPlaylist
{
    [self.navigationController presentViewController:picker animated: YES completion:nil];
}

- (void)buttonPressed:(UIButton*)sender withSong:(Song *)song
{
    if (sender.tag == InfoButton) {
        NSLog(@"Info Button pressed\n");
        //TODO: Memory allocation, only want one InfoViewController
        if (!infoView)
            infoView = [[InfoViewController alloc] initWithSong:song];
        [self.navigationController pushViewController:infoView animated:YES];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"Peer cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        cell.backgroundColor = UIColorFromRGB(0x464646);
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    if (playlist.count){
        cell.textLabel.text = [[playlist objectAtIndex:[indexPath row]] title];
        cell.detailTextLabel.text = [[playlist objectAtIndex:[indexPath row]] artistName];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.userInteractionEnabled = YES;
    }
    else{
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.userInteractionEnabled = NO;
        cell.textLabel.text = @"No Songs in Queue";
        cell.detailTextLabel.text = @"";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selected: %@\n", [tableView cellForRowAtIndexPath:indexPath].textLabel.text);
    
    if (!infoView)
        infoView = [[InfoViewController alloc] init];
    [infoView updateSong:[playlist objectAtIndex:[indexPath row]]];
    [self.navigationController pushViewController:infoView animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(playlist.count)
        return playlist.count;
    return 1;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    //[self updateQueueWithCollection:mediaItemCollection];
}


- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnecting) {
        //Loading Icon
        NSLog(@"Connecting to %@", peerID.displayName);
    } else if (state == MCSessionStateConnected) {
        //Start stream
        NSLog(@"Connected to %@", peerID.displayName);
    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"Disconnected from %@", peerID.displayName);
    }
}

-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    
}

-(void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    
}

-(void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    
}

@end
