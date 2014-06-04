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

@implementation ServerPlaylistViewController{
    BOOL shownAddButton;
}

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
    
    location = CGRectMake(location.origin.x - 20, location.origin.y, location.size.width + 15, location.size.height);
    doneButton = [[UIButton alloc] initWithFrame:location];
    
    doneButton.hidden = YES;
    
    [self.navigationController.navigationBar addSubview:djButton];
    [self.navigationController.navigationBar addSubview:doneButton];
    [djButton setContentMode:UIViewContentModeScaleAspectFit];

    [djButton setImage:[UIImage imageNamed:@"dj_inactive"] forState:UIControlStateNormal];
    [djButton setImage:[UIImage imageNamed:@"dj_active"] forState:UIControlStateSelected];
    [djButton addTarget:self action:@selector(djUpdate:) forControlEvents:UIControlEventTouchUpInside];
    [self djUpdate:nil];
    
    [doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(djUpdate:) forControlEvents:UIControlEventTouchUpInside];
    
    [albumArtwork updateSongInfo:musicPlayer.currentSong];
    
    [tableviewMenu addTarget:self action:@selector(segmentChanged) forControlEvents:UIControlEventValueChanged];
    
    if (musicPlayer.currentSong) {
        shownAddButton = YES;
    }
    else {
        shownAddButton = NO;
    }
}

- (void)djUpdate:(UIButton*)sender
{
    // Tracks segment selected else Passengers segment selected
    if ([tableviewMenu selectedSegmentIndex] == 0) {
        
    
        if (sender) {
            // User clicked djButton
            if ([mainTableView isEditing]) {
                [UIView animateWithDuration:0.5 animations:^{
                    djButton.frame = CGRectMake(self.view.frame.size.width - self.navigationController.navigationBar.frame.size.width / 8,
                                                self.navigationController.navigationBar.frame.size.height / 7, BUTTON_SIZE, BUTTON_SIZE);

                }];
                self.navigationItem.title = [[UIDevice currentDevice] name];
                doneButton.hidden = YES;
                [mainTableView setEditing:NO];
            } else {
                [UIView animateWithDuration:0.5 animations:^{
                    djButton.frame = CGRectMake(self.view.frame.size.width/2.0 - (djButton.frame.size.width/2.0), djButton.frame.origin.y, djButton.frame.size.width, djButton.frame.size.height);
                    self.navigationItem.title = @"";
                    doneButton.hidden = NO;
                }];
                [mainTableView setEditing:YES];
            }
            [self djUpdate:nil];
            
        } else {
            // User did not click djButton
            if (musicPlayer.playlist.count == 0) {
                [mainTableView setEditing:NO];
                [UIView animateWithDuration:0.5 animations:^{
                    djButton.frame = CGRectMake(self.view.frame.size.width - self.navigationController.navigationBar.frame.size.width / 8,
                                                self.navigationController.navigationBar.frame.size.height / 7, BUTTON_SIZE, BUTTON_SIZE);
                }];
                self.navigationItem.title = [[UIDevice currentDevice] name];
                doneButton.hidden = YES;
                [djButton setEnabled:NO];
            } else {
                [djButton setEnabled:YES];
            }
            
        }
    } else {
        if (sender) {
            if ([mainTableView isEditing]) {
                [UIView animateWithDuration:0.5 animations:^{
                    djButton.frame = CGRectMake(self.view.frame.size.width - self.navigationController.navigationBar.frame.size.width / 8,
                                                self.navigationController.navigationBar.frame.size.height / 7, BUTTON_SIZE, BUTTON_SIZE);
                    self.navigationItem.title = [[UIDevice currentDevice] name];
                    doneButton.hidden = YES;
                }];
                [mainTableView setEditing:NO];
            } else {
                [UIView animateWithDuration:0.5 animations:^{
                    djButton.frame = CGRectMake(self.view.frame.size.width/2.0 - (djButton.frame.size.width/2.0), djButton.frame.origin.y, djButton.frame.size.width, djButton.frame.size.height);
                    self.navigationItem.title = @"";
                    doneButton.hidden = NO;
                }];
                [mainTableView setEditing:YES];
            }
            [self djUpdate:nil];
            
        } else {
            // User did not click djButton
            if (sessionManager.connectedPeersArray.count == 0) {
                [mainTableView setEditing:NO];
                [UIView animateWithDuration:0.5 animations:^{
                    djButton.frame = CGRectMake(self.view.frame.size.width - self.navigationController.navigationBar.frame.size.width / 8,
                                                self.navigationController.navigationBar.frame.size.height / 7, BUTTON_SIZE, BUTTON_SIZE);
                    self.navigationItem.title = [[UIDevice currentDevice] name];
                    doneButton.hidden = YES;
                }];

                [djButton setEnabled:NO];
            } else {
                [djButton setEnabled:YES];
            }
        }
    }
}


- (void)segmentChanged
{
    [self djUpdate:nil];
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (musicPlayer.currentSong == nil && shownAddButton == NO) {
        [self addToPlaylist];
        shownAddButton = YES;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([mainTableView isEditing] == NO) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete && musicPlayer.playlist.count == 1) {
        [musicPlayer removeSongFromPlaylist:[indexPath row]];
        [sessionManager removeSongFromAllPeersAtIndex:[indexPath row]];
    }
    else if (editingStyle == UITableViewCellEditingStyleDelete) {
        [musicPlayer.playlist removeObjectAtIndex:[indexPath row]];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        [((GrayTableView*)tableView) adjustHeight];
        [sessionManager removeSongFromAllPeersAtIndex:[indexPath row]];
    }
    [self djUpdate:nil];
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
    
    [self djUpdate:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)connectedToPeer:(MCPeerID *)peerID
{
    //NSLog(@"connectedToPeer");
    if (musicPlayer.playlist.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (musicPlayer.currentSong) {
                [sessionManager addSong:musicPlayer.currentSong toPeer:peerID];
                [sessionManager nextSong:musicPlayer.currentSong];
            }
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

- (void)playListHasBeenUpdated
{
    [super playListHasBeenUpdated];
    [self djUpdate:nil];
 
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    [self djUpdate:nil];
}


@end
