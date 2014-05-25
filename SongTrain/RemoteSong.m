//
//  RemoteSong.m
//  SongTrain
//
//  Created by Quinton Petty on 5/2/14.
//  Copyright (c) 2014 Quinton Petty. All rights reserved.
//

#import "RemoteSong.h"

@implementation RemoteSong {
    BOOL sentRequest;
    NSThread *streamingThread;
    BOOL stillStreaming;
}

- (instancetype)initWithSong:(Song*)song fromPeer:(MCPeerID*)peer
{
    if (self = [super init]) {
        self.peer = peer;
        self.title = song.title;
        self.artistName = song.artistName;
        self.persistantID = song.persistantID;
        self.url = song.url;
        self.songLength = song.songLength;
        
        image = nil;
        sentRequest = NO;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.peer = [coder decodeObjectForKey:@"peer"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:self.peer forKey:@"peer"];
}

- (void)prepareSong{
    [[QPSessionManager sessionManager] requestToStartStreaming:self];
    //Allocate Circular buffer
    AudioFileStreamOpen((__bridge void*)self, propertyListenerCallback, packetCallback, 0, &(_fileStream));
}

- (void)setInStream:(NSInputStream *)inStream
{
    _inStream = inStream;
    [self startStreaming];
}

- (void)startStreaming
{
    if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        return [self performSelectorOnMainThread:@selector(startStreaming) withObject:nil waitUntilDone:YES];
    }
    
    self.inStream.delegate = self;
    stillStreaming = YES;
    streamingThread = [[NSThread alloc] initWithTarget:self selector:@selector(startThread) object:nil];
    [streamingThread start];
}

- (void)startThread
{
    [self.inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inStream open];
    while (stillStreaming && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ;
}


// Well Shit -> http://stackoverflow.com/questions/4051018/nsinputstream-getbuffer-length-doesnt-work
// [incomingStream getBuffer:&buff length:&len] would have been nice.
-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    if (eventCode == NSStreamEventHasBytesAvailable) {
        NSInputStream *incomingStream = (NSInputStream*)aStream;
        uint8_t buf[4096];
        
        NSInteger ret = [incomingStream read:buf maxLength:4096];
        if (ret < 0) {
            NSLog(@"Failed to read from input stream\n");
        }
        else if (ret == 0) {
            NSLog(@"End of Buffer found\n");
        }
        else {
            AudioFileStreamParseBytes(_fileStream, (UInt32)ret, buf, 0);
        }
    }
    else if (eventCode == NSStreamEventEndEncountered) {
        //close loop
        stillStreaming = NO;
    }
}


void propertyListenerCallback(void *inClientData, AudioFileStreamID inAudioFileStream, AudioFileStreamPropertyID inPropertyID, UInt32 *ioFlags)
{
    NSLog(@"Got some properties\n");
}

void packetCallback(void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void *inInputData, AudioStreamPacketDescription *inPacketDescriptions)
{
    NSLog(@"Got some packets\n");
}

- (int)getMusicPackets:(UInt32*)numOfPackets forBuffer:(AudioBufferList*)ioData
{
    //read from converter
    return 3;
}

- (UIImage*)getAlbumImage
{
    if (image)
        return image;
    
    if (sentRequest == NO){
        [[QPSessionManager sessionManager] requestAlbumArtwork:self];
        sentRequest = YES;
    }
    return nil;
}

@end
