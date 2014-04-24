//
//  ServerPlaylistViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 2/2/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "ServerPlaylistViewController.h"
#import "QPMusicPlayerController.h"
#import "QPSessionManager.h"

#define BUTTON_SIZE 30

@interface ServerPlaylistViewController ()
@property BOOL djEditing;
@end

@implementation ServerPlaylistViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    CGRect location = CGRectMake(0, albumArtwork.frame.origin.y + albumArtwork.frame.size.height, 50, 50);
    
    self.djEditing = NO;
    
    // Add Dj button for host, I think that's the only person who should have it, right?
    // TODO: reposition the dj button, alter size, ui changes and what not
    location = CGRectMake(self.view.frame.size.width - self.navigationController.navigationBar.frame.size.width / 8,
                          self.navigationController.navigationBar.frame.size.height / 7, BUTTON_SIZE, BUTTON_SIZE);
    djButton = [[UIButton alloc] initWithFrame:location];
    [self.navigationController.navigationBar addSubview:djButton];
    [djButton setContentMode:UIViewContentModeScaleAspectFit];

    [djButton setImage:[UIImage imageNamed:@"dj_inactive"] forState:UIControlStateNormal];
    [djButton setImage:[UIImage imageNamed:@"dj_active"] forState:UIControlStateSelected];
    [djButton addTarget:self action:@selector(djMode) forControlEvents:UIControlEventTouchUpInside];
    setEditing = NO;

    //[djButton addTarget:self.delegate action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
    
    [albumArtwork updateSongInfo:musicPlayer.currentSong];
    
    //[tableviewMenu addTarget:self action:@selector(turnOffEditOnUISegementSwitch) forControlEvents:UIControlEventValueChanged];
}

- (void)djMode
{
    if (self.djEditing) {
        [UIView animateWithDuration:0.5 animations:^{
            djButton.frame = CGRectMake(self.view.frame.size.width - self.navigationController.navigationBar.frame.size.width / 8,
                                        self.navigationController.navigationBar.frame.size.height / 7, BUTTON_SIZE, BUTTON_SIZE);
        }];
    }
    else {
        [UIView animateWithDuration:0.5 animations:^{
            djButton.frame = CGRectMake(self.view.frame.size.width/2.0 - (djButton.frame.size.width/2.0), djButton.frame.origin.y, djButton.frame.size.width, djButton.frame.size.height);
        }];
    }
    
    self.djEditing = !self.djEditing;
    
    if ((tableviewMenu.selectedSegmentIndex && sessionManager.connectedPeersArray.count) || musicPlayer.playlist.count) {
        setEditing = !setEditing;
        [mainTableView setEditing:setEditing animated:YES];
    }
}

- (void)turnOffEditOnUISegementSwitch
{
    [mainTableView setEditing:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    djButton.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    djButton.hidden = NO;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete && musicPlayer.playlist.count == 1) {
        [musicPlayer removeSongFromPlaylist:[indexPath row]];
        [self djMode];
        [sessionManager removeSongFromAllPeersAtIndex:[indexPath row]];
    }
    else if (editingStyle == UITableViewCellEditingStyleDelete) {
        [musicPlayer.playlist removeObjectAtIndex:[indexPath row]];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        [((GrayTableView*)tableView) adjustHeight];
        [sessionManager removeSongFromAllPeersAtIndex:[indexPath row]];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (musicPlayer.playlist.count)
        return YES;
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    Song *tempSong = [musicPlayer.playlist objectAtIndex:sourceIndexPath.row];
    [musicPlayer.playlist removeObjectAtIndex:sourceIndexPath.row];
    [musicPlayer.playlist insertObject:tempSong atIndex:destinationIndexPath.row];
    
    [sessionManager switchSongFrom:sourceIndexPath.row to:destinationIndexPath.row];
    NSLog(@"first: %ld   second: %ld\n", (long)sourceIndexPath.row, (long)destinationIndexPath.row);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    
    NSMutableArray *newSongs = [[NSMutableArray alloc] init];
    for (MPMediaItem *item in mediaItemCollection.items) {
        LocalSong *tempSong = [[LocalSong alloc] initWithOutputASBD:*(musicPlayer.audioFormat) andItem:item];
        [newSongs addObject:tempSong];
        [sessionManager addSongToAllPeers:tempSong];
    }
    
    [musicPlayer addSongsToPlaylist:newSongs];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)connectedToPeer:(MCPeerID *)peerID
{
    //NSLog(@"connectedToPeer");
    if (musicPlayer.playlist.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (Song* s in musicPlayer.playlist) {
                [sessionManager addSong:s toPeer:peerID];
            }
        });
    }
}

- (void)disconnectedFromPeer:(MCPeerID*)peerID
{
    //[musicPlayer removeSongsWithPeerID:peerID];
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainTableView reloadData];
    });
}



@end
