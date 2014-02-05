//
//  ServerPlaylistViewController.m
//  SongTrain
//
//  Created by Quinton Petty on 2/2/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "ServerPlaylistViewController.h"

@interface ServerPlaylistViewController ()

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
    
    musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    [albumArtwork addPlayer:musicPlayer];
    
    //Add whole queue instead of single song
    if ([musicPlayer nowPlayingItem]){
        Song *nowPlayingSong = [[Song alloc] init];
        nowPlayingSong.title = [[musicPlayer nowPlayingItem] valueForProperty:MPMediaItemPropertyTitle];
        nowPlayingSong.artistName = [[musicPlayer nowPlayingItem] valueForProperty:MPMediaItemPropertyArtist];
        nowPlayingSong.host = pid;
        nowPlayingSong.media = [musicPlayer nowPlayingItem];
        
        [playlist addObject:nowPlayingSong];
    }
    //Broadcast Train to others
    
    advert = [[MCNearbyServiceAdvertiser alloc] initWithPeer:pid discoveryInfo:nil serviceType:service];
    advert.delegate = self;
    
    picker.delegate = self;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:YES error:nil];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [self getAudioFromFile: [[playlist firstObject] media]];
}

-(void)viewWillAppear:(BOOL)animated
{
    NSLog(@"Advertising Peers...\n");
    [advert startAdvertisingPeer];

    /*
    const char *here = "somehting";
     
    dispatch_async(dispatch_queue_create(here, NULL),^{
        [self getAudioFromFile: [[playlist firstObject] media]];
    });
     */
}

-(void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"Stopped Advertising Peers...\n");
    [advert stopAdvertisingPeer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    //[self updateQueueWithCollection:mediaItemCollection];
    
    for (MPMediaItem *item in mediaItemCollection.items){
        Song *oneSong = [[Song alloc] init];
        oneSong.title = [item valueForProperty:MPMediaItemPropertyTitle];
        oneSong.artistName = [item valueForProperty:MPMediaItemPropertyArtist];
        oneSong.host = pid;
        oneSong.media = item;
        [playlist addObject:oneSong];
    }
    
    NSLog(@"Sending some data\n");

    NSData *dataToSend = [NSKeyedArchiver archivedDataWithRootObject:playlist];
    [mainSession sendData:dataToSend toPeers:mainSession.connectedPeers withMode:MCSessionSendDataReliable error:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [mainTableView reloadData];
}

static char *FormatError(char *str, OSStatus error)
{
    // see if it appears to be a 4-char-code
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
    return str;
}

static void AQTestBufferCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inCompleteAQBuffer) {
    struct myAQStruct *myInfo = (struct myAQStruct *)inUserData;
    NSLog(@"Buffer callback with misRunning: %d  with number : %d\n", myInfo->mIsRunning, myInfo->number);
    if (myInfo->mIsRunning == 0) return;
    NSLog(@"Filling Buffer\n");
    UInt32 numBytes;
    UInt32 nPackets = myInfo->mNumPacketsToRead;
    
    OSStatus i = AudioFileReadPackets (myInfo->mAudioFile, false, &numBytes, myInfo->mPacketDescs, myInfo->mCurrentPacket, &nPackets, inCompleteAQBuffer->mAudioData);
    char error[7];
    FormatError(error, i);
    NSLog(@"AudioFileReadPackets with error code: %s\n", error);
    
    if (nPackets > 0) {
        inCompleteAQBuffer->mAudioDataByteSize = numBytes;
        i = AudioQueueEnqueueBuffer (inAQ, inCompleteAQBuffer, (myInfo->mPacketDescs ? nPackets : 0), myInfo->mPacketDescs);
        NSLog(@"Just called enqueue buffer with error code: %d\n", i);
        myInfo->mCurrentPacket += nPackets;
    } else {
        i = AudioQueueStop (myInfo->mQueue, false);
        NSLog(@"Just called queue stop with error code: %d\n", i);
        myInfo->mIsRunning = false;
    }
}

void DeriveBufferSize (AudioStreamBasicDescription ASBDesc, UInt32 maxPacketSize, Float64 seconds, UInt32 *outBufferSize, UInt32 *outNumPacketsToRead) {
    static const int maxBufferSize = 0x50000;
    static const int minBufferSize = 0x4000;
    
    if (ASBDesc.mFramesPerPacket != 0) {
        Float64 numPacketsForTime = ASBDesc.mSampleRate / ASBDesc.mFramesPerPacket * seconds;
        *outBufferSize = numPacketsForTime * maxPacketSize;
    } else {
        *outBufferSize = maxBufferSize > maxPacketSize ? maxBufferSize : maxPacketSize;
    }
    
    if (*outBufferSize > maxBufferSize && *outBufferSize > maxPacketSize)
        *outBufferSize = maxBufferSize;
    else {
        if (*outBufferSize < minBufferSize)
            *outBufferSize = minBufferSize;
    }
    
    *outNumPacketsToRead = *outBufferSize / maxPacketSize;
}

- (void)getAudioFromFile:(MPMediaItem*)item{
    
    //NSURL *assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
    NSURL *assetURL = [NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"TheFuneral" ofType:@"m4a"]];
    
    //NSString *resourceURLString = [[[NSBundle mainBundle] resourceURL] absoluteString];
    //NSURL *assetURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@TheFuneral.m4a", resourceURLString]];
    
    UInt32 dataSize;
    OSStatus error;
    char errorString[7];
    
    //struct myAQStruct myinfo;
    myinfo.number = 76;
    
    NSLog(@"Attempt to open: %@", assetURL.absoluteString);
    
    if((error = AudioFileOpenURL((__bridge CFURLRef)assetURL, kAudioFileReadPermission, 0, &myinfo.mAudioFile))){
        FormatError(errorString, error);
        NSLog(@"Error opening url: %s\n", errorString);
        return;
    }
    
    
    AudioFileGetPropertyInfo(myinfo.mAudioFile, kAudioFilePropertyDataFormat, &dataSize, NULL);
    NSLog(@"Size of Data Format: %lu\n", (unsigned long)dataSize);
    
    if(AudioFileGetProperty(myinfo.mAudioFile, kAudioFilePropertyDataFormat, &dataSize, &myinfo.mDataFormat)){
        NSLog(@"Error getting Property\n");
        return;
    }
    
    //CAStreamBasicDescription::Print();
    
    error = AudioQueueNewOutput (&myinfo.mDataFormat, AQTestBufferCallback, &myinfo, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &myinfo.mQueue);
    NSLog(@"Just called queue new output with error code: %d\n", error);
    
    
    //Apple Example Code below
    
    UInt32 maxPacketSize;
    UInt32 propertySize = sizeof (maxPacketSize);
    AudioFileGetProperty (myinfo.mAudioFile, kAudioFilePropertyPacketSizeUpperBound, &propertySize, &maxPacketSize);
    
    DeriveBufferSize(myinfo.mDataFormat, maxPacketSize, 0.5, &myinfo.bufferByteSize, &myinfo.mNumPacketsToRead);
    
    NSLog(@"Buffer Byte size: %d\n", myinfo.bufferByteSize);
    NSLog(@"Number of Packets to read size: %d\n", myinfo.mNumPacketsToRead);
    
    bool isFormatVBR = (myinfo.mDataFormat.mBytesPerPacket == 0 || myinfo.mDataFormat.mFramesPerPacket == 0);
    
    if (isFormatVBR) {
        myinfo.mPacketDescs = (AudioStreamPacketDescription*) malloc (myinfo.mNumPacketsToRead * sizeof (AudioStreamPacketDescription));
    } else {
        myinfo.mPacketDescs = NULL;
    }
    
    UInt32 cookieSize = sizeof (UInt32);
    bool couldNotGetProperty = AudioFileGetPropertyInfo (myinfo.mAudioFile, kAudioFilePropertyMagicCookieData, &cookieSize,NULL);
    
    if (!couldNotGetProperty && cookieSize) {
        char* magicCookie = (char *) malloc (cookieSize);
        
        AudioFileGetProperty (myinfo.mAudioFile, kAudioFilePropertyMagicCookieData, &cookieSize, magicCookie);
        AudioQueueSetProperty (myinfo.mQueue, kAudioQueueProperty_MagicCookie, magicCookie, cookieSize);
        
        free (magicCookie);
    }
    myinfo.mIsRunning = true;
    myinfo.mCurrentPacket = 0;
    
    
    for (int i = 0; i < kNumberBuffers; ++i) {
        error = AudioQueueAllocateBuffer (myinfo.mQueue, myinfo.bufferByteSize, &myinfo.mBuffers[i]);
        NSLog(@"Just called queue allocate buffer with error code: %d\n", error);
        AQTestBufferCallback(&myinfo, myinfo.mQueue, myinfo.mBuffers[i]);
    }
    
    
    
    Float32 gain = 1.0;
    // Optionally, allow user to override gain setting here
    AudioQueueSetParameter (myinfo.mQueue, kAudioQueueParam_Volume, gain);
    
    myinfo.mIsRunning = true;
    NSLog(@"Set is Running to: %d and number is: %d\n", myinfo.mIsRunning, myinfo.number);
    
    error = AudioQueueStart (myinfo.mQueue, NULL);
    NSLog(@"Just called queue start with error code: %d\n", error);
    
    /*
    do {
        CFRunLoopRunInMode (kCFRunLoopDefaultMode, 0.25, false);
        //NSLog(@"One time through loop\n");
    } while (myinfo.mIsRunning);
    
    NSLog(@"After Loop\n");
    CFRunLoopRunInMode (kCFRunLoopDefaultMode, 1, false);
    */
    
     
    //End Apple Example Code
    
    /*
    i = AudioQueueSetParameter(myinfo.mQueue, kAudioQueueParam_Volume, 1);
    NSLog(@"Just called queue set parameter with error code: %d\n", i);
    
    i = AudioQueueEnqueueBuffer(myinfo.mQueue, myinfo.mBuffers[0], 0, 0);
    NSLog(@"Just called queue enqueue buffer with error code: %d\n", i);
    
    i = AudioQueuePrime(myinfo.mQueue, 0, NULL);
    NSLog(@"Just called queue prime with error code: %d\n", i);
    
    i = AudioQueueStart(myinfo.mQueue, NULL);
    NSLog(@"Just called queue start with error code: %d\n", i);
    */
    /*
     CFDictionaryRef dic;
     UInt32 dataSize;
     
     const void *keys;
     const void *values;
     
    if(AudioFileGetProperty(inputFile, kAudioFilePropertyInfoDictionary, &dataSize, &dic)){
        NSLog(@"Error getting Property\n");
        return;
    }

    NSDictionary *newDict = (__bridge_transfer NSDictionary*)dic;
    NSLog(@"Dictionary Count: %@\n", newDict);
    
    
    
    CFDictionaryGetKeysAndValues(dic, &keys, &values);
    
    NSLog(@"Key: %s\nValue: %s\n", ((char*)keys), ((char*)values));
    
    NSLog(@"Count: %lu\n", CFDictionaryGetCount(dic));
    
    for (int i = 0; i < CFDictionaryGetCount(dic); i++) {
        NSLog(@"Key: %s\nValue: %s\n", ((char*)keys)[i], ((char*)values)[i]);
    }
     */
}

-(void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{
    NSLog(@"Got Invite from %@", peerID.displayName);
    invitationHandler(YES,mainSession);
}

-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnecting) {
        //Loading Icon
        NSLog(@"Connecting to %@", peerID.displayName);
    } else if (state == MCSessionStateConnected) {
        //Start stream
        NSLog(@"Connected to %@", peerID.displayName);
        if (playlist.count) {
            NSData *dataToSend = [NSKeyedArchiver archivedDataWithRootObject:playlist];
            [mainSession sendData:dataToSend toPeers:[NSArray arrayWithObject:peerID] withMode:MCSessionSendDataReliable error:nil];
        }
    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"Disconnected from %@", peerID.displayName);
        //Remove songs from disconnected peer
        int i = 0;
        while (i < playlist.count) {
            //NSLog(@"Looking at song: %@", [playlist objectAtIndex:i]);
            //NSLog(@"Host is: %@", [[playlist objectAtIndex:i] host]);
            if ([peerID.displayName isEqualToString:[ (MCPeerID*)[[playlist objectAtIndex:i] host] displayName]]) {
                [playlist removeObjectAtIndex:i];
            }
            else{
                i++;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [mainTableView reloadData];
        });
    }
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSMutableArray *songRequests = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    for (Song *one in songRequests) {
        [playlist addObject:one];
    }
    NSLog(@"Sending ACK from server\n");
    NSData *dataToSend = [NSKeyedArchiver archivedDataWithRootObject:playlist];
    [mainSession sendData:dataToSend toPeers:mainSession.connectedPeers withMode:MCSessionSendDataReliable error:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainTableView reloadData];
    });
}

@end
