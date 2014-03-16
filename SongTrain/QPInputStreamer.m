//
//  QPInputStreamer.m
//  SongTrain
//
//  Created by Quinton Petty on 2/25/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "QPInputStreamer.h"

@implementation QPInputStreamer{
    
    NSInputStream *input;
    NSThread *musicThread;
    
    struct GraphHelper graphHelp;
    
    AUGraph graph;
    AudioUnit outputUnit;
    
    AudioStreamBasicDescription audioFormat;
}


- (void)setInputStream:(NSInputStream*)inputStream
{
    input = inputStream;
    
    if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        return [self performSelectorOnMainThread:@selector(makeThread) withObject:nil waitUntilDone:YES];
    }
    
    [self makeThread];
}

- (void)makeThread
{
    NSLog(@"Allocating and starting music thread\n");
    musicThread = [[NSThread alloc] initWithTarget:self selector:@selector(start) object:nil];
    [musicThread start];
}

- (void)start
{
    [input scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [input open];
    
    [self initConverter];
    [self initBuffer];
    [self initAudioGraph];
    while ([[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ;
}

- (void)initConverter
{
    // Describe format
	audioFormat.mSampleRate			= 44100.00;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= 2;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= 4;
	audioFormat.mBytesPerFrame		= 4;
    
    AudioConverterNew(_currentSong.asbd, &audioFormat, &graphHelp.converter);
    graphHelp.outputDescription = &audioFormat;
}

- (void)initBuffer
{
    int32_t spaceAvailableInBuffer;
    size_t readBytes;
    
    uint8_t buffer[256];
    
    TPCircularBufferInit(&graphHelp.audioBuffer, kBufferLength);
    
    
    //Get rid of temp buffer
    do {
        TPCircularBufferHead(&graphHelp.audioBuffer, &spaceAvailableInBuffer);
        readBytes = [input read:buffer maxLength:sizeof(buffer)];
        NSLog(@"Adding %zu bytes to the circular buffer with %d filled\n", readBytes, spaceAvailableInBuffer);
        NSLog(@"Buffer length: %d    Buffer fillcount: %d\n", graphHelp.audioBuffer.length, graphHelp.audioBuffer.fillCount);
        TPCircularBufferProduceBytes(&graphHelp.audioBuffer, buffer, (int32_t)readBytes);
    } while (spaceAvailableInBuffer > kBufferLength / 2);
    
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
	playbackCallbackStruct.inputProcRefCon = &graphHelp;
	
	//now set the callback on the output node, this callback gets called whenever the AUGraph needs samples
	err = AUGraphSetNodeInputCallback(graph, outputNode, 0, &playbackCallbackStruct);
	NSAssert(err == noErr, @"Error setting effects callback.");
	
	//so far we have not set any property descriptions on the outputAudioUnit, these describe the format of the audio being played
	
	//set the outputAudioUnit input properties
	err = AudioUnitSetProperty(outputUnit,
							   kAudioUnitProperty_StreamFormat,
							   kAudioUnitScope_Input,
							   0,
							   &audioFormat,
							   sizeof(audioFormat));
	NSAssert(err == noErr, @"Error setting RIO input property.");
	
	//now lets check the format again
	NSLog(@"AudioStreamBasicDescription has been set, notice you now see the sample rate.");
	
    
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
	err = AUGraphStart(graph);
	NSAssert(err == noErr, @"Error starting graph.");
}

-(BOOL)connectOutputBus:(UInt32)sourceOutputBusNumber ofNode:(AUNode)sourceNode toInputBus:(UInt32)destinationInputBusNumber ofNode:(AUNode)destinationNode inGraph:(AUGraph)aGraph error:(NSError **)error {
	
	// Connect converter to mixer
	OSStatus status = AUGraphConnectNodeInput(aGraph, sourceNode, sourceOutputBusNumber, destinationNode, destinationInputBusNumber);
	if (status != noErr) {
        NSLog(@"Couldn't connect converter to output\n");
		return NO;
    }
	
	return YES;
}

/*
-(UInt32)getNextPacket
{
    int32_t availableBytes;
    
    void *nextData = TPCircularBufferTail(&audioBuffer, &availableBytes);
    
    if (nextData) {
        TPCircularBufferConsume(&audioBuffer, 2);
        return *(UInt32*)nextData;
    }
    else
        return 0;
}
*/
static OSStatus audioOutputCallback(void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData) {
	
	
	struct GraphHelper *audioPlayback = (struct GraphHelper *)inRefCon;
	
	//cast the buffer as an UInt32, cause our samples are in that format
	//UInt32 *frameBuffer = ioData->mBuffers[0].mData;
    
	if (inBusNumber == 0){
		//loop through the buffer and fill the frames, this is really inefficient
		//should be using a memcpy, but we will leave that for later
        //NSLog(@"inNumberFrames: %d\n", (unsigned int)inNumberFrames);
        
        UInt32 numPacketsNeeded = inNumberFrames / audioPlayback->outputDescription->mFramesPerPacket;
        //NSLog(@"Need %d packets and possibly wrong division: %d\n", numPacketsNeeded, inNumberFrames / audioPlayback->outputDescription->mFramesPerPacket);
        
        //NSLog(@"mData: %d\n", ioData->mBuffers[0].mData);
        //NSLog(@"AudioBufferList => Number of Buffers: %d First buffer size %d\n", ioData->mNumberBuffers, ioData->mBuffers[0].mDataByteSize);
        
        NSLog(@"ioData before: size:%d   data:%d\n", ioData->mBuffers[0].mDataByteSize, ioData->mBuffers[0].mData);
        OSStatus err = AudioConverterFillComplexBuffer(audioPlayback->converter, converterInputCallback, audioPlayback, &numPacketsNeeded, ioData, nil);
        NSLog(@"ioData after: size:%d   data:%d\n", ioData->mBuffers[0].mDataByteSize, ioData->mBuffers[0].mData);
        
        NSLog(@"Just called fill complex buffer with error: %d\n", (int)err);
	}
	
	//dodgy return :)
	return 0;
}

OSStatus converterInputCallback(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription  **outDataPacketDescription, void *inUserData)
{
    struct GraphHelper *audioPlayback = (struct GraphHelper *)inUserData;
    //NSLog(@"If not null expecting audiostreampacketdescriptions: %d\n", outDataPacketDescription);
    
    //NSLog(@"Current Thread: %@\n", [NSThread currentThread]);
    //NSLog(@"mData beginning converter: %d\n", ioData->mBuffers[0].mData);
    
    UInt32 i, dataOffset = 0;
    for (i = 0; i < *ioNumberDataPackets + 1; i++) {
        int32_t availableBytes;
        
        void *buffer = TPCircularBufferTail(&audioPlayback->audioBuffer, &availableBytes);
        //TODO: If availableBytes is too small break
        AudioStreamPacketDescription *aspd = audioPlayback->packetDescriptions + i;
        //NSLog(@"packetDescripctions: %d      packetDescriptions + i: %d\n", audioPlayback->packetDescriptions, audioPlayback->packetDescriptions + i);
        memcpy(aspd, buffer, sizeof(AudioStreamPacketDescription));
        aspd->mStartOffset = dataOffset;
        //NSLog(@"Packet Description => DataByteSize %d StartOffset: %lld Variable Frame in Packet: %d\n", aspd->mDataByteSize, aspd->mStartOffset, aspd->mVariableFramesInPacket);
        
        TPCircularBufferConsume(&audioPlayback->audioBuffer, sizeof(AudioStreamPacketDescription));
        
        buffer = TPCircularBufferTail(&audioPlayback->audioBuffer, &availableBytes);
        //NSLog(@"i: %d   ioNumberDataPackets: %d   buffer: %d    availableBytes: %d\n", i, *ioNumberDataPackets, buffer, availableBytes);
        memcpy(audioPlayback->conversionBuffer + dataOffset, buffer, aspd->mDataByteSize);
        
        TPCircularBufferConsume(&audioPlayback->audioBuffer, aspd->mDataByteSize);
        dataOffset += aspd->mDataByteSize;
    }
    ioData->mBuffers[0].mData = audioPlayback->conversionBuffer;
    ioData->mBuffers[0].mDataByteSize = dataOffset;
    //NSLog(@"data Offset: %d\n", (unsigned int)dataOffset);
    *ioNumberDataPackets = i;
    *outDataPacketDescription = audioPlayback->packetDescriptions;
    
    //NSLog(@"mData end converter: %d\n", ioData->mBuffers[0].mData);
    //NSLog(@"data Offset: %d  ioNumberDataPackets: %d mData %d\n", (unsigned int)dataOffset, (unsigned int)*ioNumberDataPackets, ioData->mBuffers[0].mData);
    
    return 0;
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

@end
