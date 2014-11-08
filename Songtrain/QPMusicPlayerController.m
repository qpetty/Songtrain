//
//  QPMusicPlayerController.m
//  SongTrain
//
//  Created by Quinton Petty on 2/10/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "QPMusicPlayerController.h"

@implementation QPMusicPlayerController{
    AUGraph graph;
    AudioUnit outputUnit;
    
    MPNowPlayingInfoCenter *nowPlayingCenter;
    NSTimer *timer;
    
    BOOL isServer;
}

+ (instancetype)sharedMusicPlayer {
    static QPMusicPlayerController *sharedMusicPlayer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMusicPlayer = [[self alloc] init];
    });
    return sharedMusicPlayer;
}

- (id)init {
    if (self = [super init]) {
        _audioFormat = malloc(sizeof(AudioStreamBasicDescription));
        [self initOutputDescription];
        [self initAudioGraph];
        
        _playlist = [[NSMutableArray alloc] init];
        nowPlayingCenter = [MPNowPlayingInfoCenter defaultCenter];
        timer = nil;
        
        _currentlyPlaying = NO;
        isServer = YES;
    }
    return self;
}

-(void)reset
{
    AUGraphStop(graph);
    _currentlyPlaying = NO;
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    isServer = NO;
    
    [self willChangeValueForKey:@"currentSong"];
    _currentSong = nil;
    [self didChangeValueForKey:@"currentSong"];
    
    [self willChangeValueForKey:@"currentSongTime"];
    _currentSongTime.location = 0;
    _currentSongTime.length = 0;
    [self didChangeValueForKey:@"currentSongTime"];
    
    [self willChangeValueForKey:@"playlist"];
    [_playlist removeAllObjects];
    [self didChangeValueForKey:@"playlist"];
}

- (void)resetToServer
{
    [self reset];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    isServer = YES;
    
    MPMediaItem *currentItem = [[MPMusicPlayerController systemMusicPlayer] nowPlayingItem];
    if (currentItem && [currentItem valueForProperty:MPMediaItemPropertyAssetURL]){
        [self updateCurrentSong:[[LocalSong alloc] initWithItem:currentItem andOutputASBD:*(self.audioFormat)]];
        [self.currentSong prepareSong];
    }
}

- (void)resetToClient
{
    [self reset];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    AUGraphStart(graph);
}

- (void)addSongToPlaylist:(Song*)song
{
    [self willChangeValueForKey:@"playlist"];
    [_playlist addObject:song];
    [self didChangeValueForKey:@"playlist"];
    [self.delegate songAdded:song atIndex:self.playlist.count - 1];
}

- (void)addSongsToPlaylist:(NSMutableArray*)songs
{
    for (Song *item in songs){
        [self addSongToPlaylist:item];
    }

    NSLog(@"Added %lu songs to the playlist\n", (unsigned long)songs.count);
}

- (void)removeSongFromPlaylist:(NSUInteger)ndx
{
    Song *removedSong = [_playlist objectAtIndex:ndx];
    [self willChangeValueForKey:@"playlist"];
    [_playlist removeObjectAtIndex:ndx];
    [self didChangeValueForKey:@"playlist"];
    
    [self.delegate songRemoved:removedSong atIndex:ndx];
}

- (void)removeSongIndexesFromPlaylist:(NSIndexSet*)set {
    [self willChangeValueForKey:@"playlist"];
    [_playlist removeObjectsAtIndexes:set];
    [self didChangeValueForKey:@"playlist"];
    
    [self.delegate songsRemovedAtIndexSet:set];
}

- (void)switchSongFromIndex:(NSUInteger)ndx to:(NSUInteger)ndx2
{
    [self willChangeValueForKey:@"playlist"];
    Song *tempSong = [_playlist objectAtIndex:ndx];
    [_playlist removeObjectAtIndex:ndx];
    [_playlist insertObject:tempSong atIndex:ndx2];
    [self didChangeValueForKey:@"playlist"];
    
    [self.delegate songMoved:tempSong fromIndex:ndx toIndex:ndx2];
}

- (void)play
{
    if (_currentlyPlaying == NO) {
        if (![_playlist count] && !self.currentSong)
            return;
        
        if (!_currentSong) {
            [self skip];
        }
        OSErr err = AUGraphStart(graph);
        
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(addOneToTime) userInfo:nil repeats:YES];
        
        if (err != noErr) {
            NSAssert(err == noErr, @"Error starting graph.");
        }
        
        [self willChangeValueForKey:@"currentlyPlaying"];
        _currentlyPlaying = YES;
        [self didChangeValueForKey:@"currentlyPlaying"];
    }
    else {
        AUGraphStop(graph);
        
        if (timer) {
            [timer invalidate];
            timer = nil;
        }
        
        [self willChangeValueForKey:@"currentlyPlaying"];
        _currentlyPlaying = NO;
        [self didChangeValueForKey:@"currentlyPlaying"];
    }
}

- (void)skip
{
    if (isServer) {
        [[_playlist firstObject] prepareSong];
        [self nextSong];
    }
    else {
        NSLog(@"Count vote\n");
    }
}

- (void)nextSong
{
    if ([_playlist count]) {
        
        [_currentSong cleanUpSong];
        
        [self willChangeValueForKey:@"playlist"];
            [self updateCurrentSong:[_playlist firstObject]];
            //[_playlist removeObjectAtIndex:0];
            [self removeSongFromPlaylist:0];
        [self didChangeValueForKey:@"playlist"];
    }
}

-(void)updateCurrentSong:(Song*)song {
    [self willChangeValueForKey:@"currentSong"];
    _currentSong = song;
    [self didChangeValueForKey:@"currentSong"];
    
    [self willChangeValueForKey:@"currentSongTime"];
    _currentSongTime.location = 0;
    _currentSongTime.length = _currentSong.songLength;
    [self didChangeValueForKey:@"currentSongTime"];
    
    
    [self updateNowPlaying];
}

- (void)updateNowPlaying
{
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    
    if (_currentSong.title) {
        [keys addObject:MPMediaItemPropertyTitle];
        [objects addObject:_currentSong.title];
    }

    if (_currentSong.artistName) {
        [keys addObject:MPMediaItemPropertyArtist];
        [objects addObject:_currentSong.artistName];
    }
    
    UIImage *songImage = _currentSong.albumImage;
    
    if (songImage == nil) {
        songImage = [UIImage imageNamed:@"albumart_default"];
    }
    
    [keys addObject:MPMediaItemPropertyArtwork];
    [objects addObject:[[MPMediaItemArtwork alloc] initWithImage:songImage]];
    
    [keys addObject:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [objects addObject:[NSNumber numberWithInteger:self.currentSongTime.location]];
    
    [keys addObject:MPMediaItemPropertyPlaybackDuration];
    [objects addObject: [NSNumber numberWithInteger:self.currentSongTime.length]];
    
    NSDictionary *info = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
    [nowPlayingCenter setNowPlayingInfo:info];
}

- (void)addOneToTime
{
    [self currentTime:_currentSongTime.location + 1];
}

- (void)currentTime:(NSUInteger)time
{
    [self willChangeValueForKey:@"currentSongTime"];
    _currentSongTime.location = time;
    if(_currentSongTime.location > _currentSongTime.length)
        _currentSongTime.location = _currentSongTime.length;
    [self didChangeValueForKey:@"currentSongTime"];
}

- (BOOL)isRunning {
    Boolean isRunning;
    
    AUGraphIsRunning(graph, &isRunning);
    if (isRunning) {
        return YES;
    }
    return NO;
}

- (void)initOutputDescription
{
    // Describe format
	_audioFormat->mSampleRate			= 44100.00;
    _audioFormat->mFormatID             = kAudioFormatLinearPCM;
	_audioFormat->mFormatFlags          = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	_audioFormat->mFramesPerPacket      = 1;
	_audioFormat->mChannelsPerFrame     = 2;
	_audioFormat->mBitsPerChannel		= 16;
	_audioFormat->mBytesPerPacket		= 4;
	_audioFormat->mBytesPerFrame		= 4;
}

- (void)initAudioGraph
{
    //the AUNode
	AUNode outputNode;
    
	//create the graph
	OSErr err = noErr;
	err = NewAUGraph(&graph);
	//throw an exception if the graph couldn't be created.
	NSAssert(err == noErr, @"Error creating graph.");
    
    //first describe the node, graphs are made up of nodes connected together, in this graph there is only one node.
	//the descriptions for the components
    //describe the node, this is our output node it is of type remoteIO
    
	AudioComponentDescription outputDescription;
	outputDescription.componentFlags = 0;
	outputDescription.componentFlagsMask = 0;
	outputDescription.componentType = kAudioUnitType_Output;
	outputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	outputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    
	//add the node to the graph.
	err = AUGraphAddNode(graph, &outputDescription, &outputNode);
	//throw an exception if we couldnt add it
	NSAssert(err == noErr, @"Error creating output node.");
    
	//there are three steps, we open the graph, initialise it and start it.
	//when we open it (from the doco) the audio units belonging to the graph are open but not initialized. Specifically, no resource allocation occurs.
	err = AUGraphOpen(graph);
	NSAssert(err == noErr, @"Error opening graph.");
	
	//now that the graph is open we can get the AudioUnits that are in the nodes (or node in this case)
	//get the output AudioUnit from the graph, we supply a node and a description and the graph creates the AudioUnit which
	//we then request back from the graph, so we can set properties on it, such as its audio format
	err = AUGraphNodeInfo(graph, outputNode, &outputDescription, &outputUnit);
	NSAssert(err == noErr, @"Error getting output AudioUnit.");
	
	// Set up the master fader callback
	AURenderCallbackStruct playbackCallbackStruct;
	playbackCallbackStruct.inputProc = audioOutputCallback;
	//set the reference to "self" this becomes *inRefCon in the playback callback
	//as the callback is just a straight C method this is how we can pass it an objective-C class
	playbackCallbackStruct.inputProcRefCon = (__bridge void*)self;
	
	//now set the callback on the output node, this callback gets called whenever the AUGraph needs samples
	err = AUGraphSetNodeInputCallback(graph, outputNode, 0, &playbackCallbackStruct);
	NSAssert(err == noErr, @"Error setting effects callback.");
	
	//so far we have not set any property descriptions on the outputAudioUnit, these describe the format of the audio being played
	
	//set the outputAudioUnit input properties
	err = AudioUnitSetProperty(outputUnit,
							   kAudioUnitProperty_StreamFormat,
							   kAudioUnitScope_Input,
							   0,
							   _audioFormat,
							   sizeof(AudioStreamBasicDescription));
	NSAssert(err == noErr, @"Error setting RIO input property.");
	
	//now lets check the format again
	NSLog(@"AudioStreamBasicDescription has been set, notice you now see the sample rate.");
	
    
    
	UInt32 maxFramesPerSlice = 4096;
	err = AudioUnitSetProperty(outputUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, sizeof(maxFramesPerSlice));
	NSAssert(err == noErr, @"Error setting RIO input property.");
    
    /*
     AudioStreamBasicDescription audioStreamBasicDescription;
     UInt32 audioStreamBasicDescriptionsize = sizeof (AudioStreamBasicDescription);
     
     AudioUnitGetProperty(outputUnit,
     kAudioUnitProperty_StreamFormat,
     kAudioUnitScope_Input,
     0, // input bus
     &audioStreamBasicDescription,
     &audioStreamBasicDescriptionsize);
     NSLog (@"Output Audio Unit: User input AudioStreamBasicDescription\n Sample Rate: %f\n Channels: %ld\n Bits Per Channel: %ld",
     audioStreamBasicDescription.mSampleRate, audioStreamBasicDescription.mChannelsPerFrame,
     audioStreamBasicDescription.mBitsPerChannel);
     */
    
    
	//we then initiailze the graph, this (from the doco):
	//Calling this function calls the AudioUnitInitialize function on each opened node or audio unit that is involved in a interaction.
	//If a node is not involved, it is initialized after it becomes involved in an interaction.
	err = AUGraphInitialize(graph);
	NSAssert(err == noErr, @"Error initializing graph.");
	
	//this prints out a description of the graph, showing the nodes and connections, really handy.
	//this shows in the console (Command-Shift-R to see it)
	CAShow(graph);
	
	//the final step, as soon as this is run, the graph will start requesting samples. some people would put this on the play button
	//but ive found that sometimes i get a bit of a pause so i let the callback get called from the start and only start filling the buffer
	//with samples when the play button is hit.
	//the doco says :
	//this function starts rendering by starting the head node of an audio processing graph. The graph must be initialized before it can be started.
	//err = AUGraphStart(graph);
	//NSAssert(err == noErr, @"Error starting graph.");
}

static OSStatus audioOutputCallback(void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData) {
	
	
	QPMusicPlayerController *audioPlayback = (__bridge QPMusicPlayerController *)(inRefCon);
    
	OSStatus err = -1;
	//cast the buffer as an UInt32, cause our samples are in that format
	//UInt32 *frameBuffer = ioData->mBuffers[0].mData;
    
    //NSLog(@"Is main Thread %@\n", [NSThread isMainThread] ? @"YES" : @"NO");
    
	if (inBusNumber == 0 && audioPlayback.currentlyPlaying){
		//loop through the buffer and fill the frames, this is really inefficient
		//should be using a memcpy, but we will leave that for later
        //NSLog(@"inNumberFrames: %d\n", (unsigned int)inNumberFrames);
        
        UInt32 numPacketsNeeded = inNumberFrames / audioPlayback.audioFormat->mFramesPerPacket;
        //NSLog(@"Need %d packets and possibly wrong division: %d\n", numPacketsNeeded, inNumberFrames / audioPlayback->outputDescription->mFramesPerPacket);
        
        //NSLog(@"mData: %d\n", ioData->mBuffers[0].mData);
        //NSLog(@"AudioBufferList => Number of Buffers: %d First buffer size %d\n", ioData->mNumberBuffers, ioData->mBuffers[0].mDataByteSize);
        
        //NSLog(@"ioData before: size:%d   data:%d\n", ioData->mBuffers[0].mDataByteSize, ioData->mBuffers[0].mData);
        
        //NSLog(@"address %d\n", &numPacketsNeeded);
        
        err = [audioPlayback.currentSong getMusicPackets:&numPacketsNeeded forBuffer:ioData];

        if (err == -2) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [audioPlayback skip];
            });
        }
        
        //err = AudioConverterFillComplexBuffer(audioPlayback->converter, converterInputCallback, audioPlayback, &numPacketsNeeded, ioData, nil);
        //NSLog(@"ioData after: size:%d   data:%d\n", ioData->mBuffers[0].mDataByteSize, ioData->mBuffers[0].mData);
        
        //NSLog(@"Song: %@\n", audioPlayback.currentSong.title);
        
        if (err) {
            char error[6];
            FormatError(error, err);
            NSLog(@"Just called fill complex buffer with error: %s\n", error);
        }
	}
    
	if (err) {
        for (int i = 0; i < ioData->mBuffers[0].mDataByteSize; i++) {
            *((uint8_t*)(ioData->mBuffers[0].mData + i)) = 0;
        }
    }
	//dodgy return :)
	return err;
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

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)dealloc
{
    if (_audioFormat){
        free(_audioFormat);
        _audioFormat = NULL;
    }
}

@end
