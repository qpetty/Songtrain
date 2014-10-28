//
//  SoundCloudSong.m
//  Songtrain
//
//  Created by Quinton Petty on 10/18/14.
//  Copyright (c) 2014 Octave Labs LLC. All rights reserved.
//

#import "SoundCloudSong.h"
#import "CocoaSoundCloudUI/Sources/SoundCloudUI/SCUI.h"

#define MUSIC_PACKET_SIZE 65536

@implementation SoundCloudSong {
    NSMutableData *songData, *oneCallbackOfData;
    AudioConverterRef converter;
    AudioFileStreamID filestream;
    AudioStreamPacketDescription aspds[256];
    
    BOOL setOutputASBD, readyWithPackets;
    
    NSInputStream *musicStream;
    
    NSUInteger nextByteToRead;
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        self.url = url;
        songData = nil;
        setOutputASBD = readyWithPackets = NO;
        nextByteToRead = 0;
    }
    return self;
}

-(instancetype)initWithSoundCloudDictionary:(NSDictionary*)dic {
    if (self = [self initWithURL:[NSURL URLWithString:dic[@"uri"]]]) {
        
        self.title = dic[@"title"];
        self.artistName = dic[@"user"][@"username"];
        self.songLength = [dic[@"duration"] floatValue] / 1000.0;
        self.musicURL = [NSURL URLWithString:dic[@"stream_url"]];

        NSLog(@"Creating SoundCloudSong from: %@", dic);
    }
    return self;
}

-(instancetype)initWithSong:(Song*)song {
    if (self = [self initWithURL:song.url]) {
        
        self.title = song.title;
        self.artistName = song.artistName;
        self.songLength = song.songLength;
        self.musicURL = song.musicURL;
        
        NSLog(@"Creating SoundCloudSong from: %@", song);
    }
    return self;
}

-(void)setInputASBDBecauseICantReachItAnotherWay {
    self.inputASDBIsSet = YES;
    NSLog(@"set inputASBD");
}

-(void)initConverter {
    if (setOutputASBD == NO || self.inputASDBIsSet == NO) {
        NSLog(@"all ASBDs not set yet");
        return;
    }
    oneCallbackOfData = [[NSMutableData alloc] init];
    AudioConverterNew(self.inputASBD, outputASBD, &converter);
}

-(void)setOutputASBD:(AudioStreamBasicDescription)audioStreanBasicDescription {
    memcpy(outputASBD, &audioStreanBasicDescription, sizeof(AudioStreamBasicDescription));
    setOutputASBD = YES;
    [self initConverter];
}

-(void)prepareSong {
    NSLog(@"preparing SoundCloudSong");
    
    OSStatus error = AudioFileStreamOpen((__bridge void*)self, fileStreamPropertyCallback, fileStreamDataCallback, kAudioFileMP3Type, &filestream);
    if (error) {
        char errorString[7];
        FormatError(errorString, error);
        NSLog(@"Error opening file stream: %s\n", errorString);
    }
    
    //dispatch_async(dispatch_get_main_queue(), ^{
        [self requestSongData];
    //});
}

- (void)requestSongData {
 
    NSString *songURL = [NSString stringWithFormat:@"%@?oauth_token=%@", self.musicURL.absoluteString, [SCSoundCloud account].oauthToken];
    self.musicURL = [NSURL URLWithString:songURL];
    NSLog(@"Trying to get %@", songURL);
    
    songData = [[NSMutableData alloc] init];
    [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:self.musicURL] delegate:self];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //NSLog(@"Recived some data: %lu", (unsigned long)data.length);

    OSStatus error = AudioFileStreamParseBytes(filestream, (UInt32)data.length, data.bytes, 0);
    
    if (error) {
        char errorString[7];
        FormatError(errorString, error);
        NSLog(@"Error in stream parsing bytes: %s\n", errorString);
    }
}

#pragma mark Audio File Stream Services Methods

void fileStreamPropertyCallback(void *inClientData, AudioFileStreamID inAudioFileStream, AudioFileStreamPropertyID inPropertyID, UInt32 *ioFlags)
{
    SoundCloudSong *song = (__bridge SoundCloudSong *)inClientData;
    UInt32 propertySize;
    
    NSLog(@"found property '%c%c%c%c'\n", (char)(inPropertyID>>24)&255, (char)(inPropertyID>>16)&255, (char)(inPropertyID>>8)&255, (char)inPropertyID&255);
    
    if (inPropertyID == kAudioFileStreamProperty_DataFormat) {
        propertySize = sizeof(AudioStreamBasicDescription);
        AudioFileStreamGetProperty(inAudioFileStream, inPropertyID, &propertySize, song.inputASBD);
        if (propertySize == sizeof(AudioStreamBasicDescription)) {
            [song setInputASBDBecauseICantReachItAnotherWay];
            NSLog(@"Entire AudioStreamBasicDescription found\n");
        }
    }
    else if (inPropertyID == kAudioFileStreamProperty_ReadyToProducePackets) {
        [song initConverter];
        song->readyWithPackets = YES;
    }
    else if (inPropertyID == kAudioFileStreamProperty_FileFormat){
        NSLog(@"Found FileFormate\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_FormatList){
        NSLog(@"Found FormatList\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_MagicCookieData){
        NSLog(@"Found Magic Cookie data\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_AudioDataByteCount){
        NSLog(@"Found data bytes count\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_AudioDataPacketCount){
        NSLog(@"Found data packet count\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_MaximumPacketSize){
        NSLog(@"Found max packet size\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_DataOffset){
        NSLog(@"Found data offsett\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_ChannelLayout){
        NSLog(@"Found channel layout\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_PacketToFrame){
        NSLog(@"Found packet to frame\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_FrameToPacket){
        NSLog(@"Found frame to packet\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_PacketToByte){
        NSLog(@"Found packet to byte\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_ByteToPacket){
        NSLog(@"Found byte to packet\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_PacketTableInfo){
        NSLog(@"Found packet table info\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_PacketSizeUpperBound){
        NSLog(@"Found packet size upper bound\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_AverageBytesPerPacket){
        NSLog(@"Found average bytes per packet\n");
    }
    else if (inPropertyID == kAudioFileStreamProperty_BitRate){
        NSLog(@"Found bitrate\n");
    }
}

void fileStreamDataCallback(void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void *inInputData,
                            AudioStreamPacketDescription *inPacketDescriptions)
{
    SoundCloudSong *song = (__bridge SoundCloudSong *)inClientData;
    
    //NSLog(@"Audio Stream Services Data Callback\n");
   // NSLog(@"should add %d packets to our buffer", inNumberPackets);
    for (int i = 0; i < inNumberPackets; i++) {
        //inPacketDescriptions[i].mStartOffset += song->songData.length + sizeof(AudioStreamPacketDescription);
        [song->songData appendBytes:&inPacketDescriptions[i] length:sizeof(AudioStreamPacketDescription)];
        [song->songData appendBytes:inInputData + inPacketDescriptions[i].mStartOffset length:inPacketDescriptions[i].mDataByteSize];
        //addPacketToList(myInfo, inPacketDescriptions[i].mVariableFramesInPacket, inPacketDescriptions[i].mDataByteSize, inInputData + inPacketDescriptions[i].mStartOffset);
    }
    //NSLog(@"songData is now %lu long", (unsigned long)song->songData.length);
}

#pragma mark Music Methods

-(NSData *)getNextPacketofMaxBytes:(NSInteger)maxBytes {
    NSUInteger len = MUSIC_PACKET_SIZE;
    NSLog(@"len = %lu", len);
    if (len > maxBytes) {
        len = maxBytes;
        NSLog(@"len(maxBytes) = %lu", len);
    }
    if (len > songData.length - nextByteToRead) {
        len = songData.length - nextByteToRead;
        NSLog(@"len(songData.length) = %lu", len);
    }
    
    NSLog(@"Next byte %lu maxBytes: %lu songData.length: %lu", nextByteToRead, maxBytes, songData.length);
    NSRange range = NSMakeRange(nextByteToRead, len);
    nextByteToRead += len;
    NSLog(@"Sent %lu bytes", len);
    return len == 0 ? nil : [songData subdataWithRange:range];
}

- (int)getMusicPackets:(UInt32*)numOfPackets forBuffer:(AudioBufferList*)ioData
{
    OSStatus err = -5;
    if (readyWithPackets == YES) {
        err = AudioConverterFillComplexBuffer(converter, soundCloudConverterInputCallback, (__bridge void*)self, numOfPackets, ioData, NULL);
    }

    return err;
}

OSStatus soundCloudConverterInputCallback(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription  **outDataPacketDescription, void *inUserData)
{
    SoundCloudSong *song = (__bridge SoundCloudSong *)inUserData;
    //printf("number: %d\n", *ioNumberDataPackets);
    //NSLog(@"would like %u packets", (unsigned int)*ioNumberDataPackets);
    //NSLog(@"buffers: %d", ioData->mNumberBuffers);
    
    if (song->songData == nil) {
        return -5;
    }
    if (song->nextByteToRead >= song->songData.length) {
        return -2;
    }
    
    song->oneCallbackOfData.length = 0;
    
    for (int i = 0; i < *ioNumberDataPackets; i++) {
        memcpy(&song->aspds[i], song->songData.bytes + song->nextByteToRead, sizeof(AudioStreamPacketDescription));
        song->aspds[i].mStartOffset = song->oneCallbackOfData.length;
        song->nextByteToRead += sizeof(AudioStreamPacketDescription);
        [song->oneCallbackOfData appendBytes:song->songData.bytes + song->nextByteToRead length:song->aspds[i].mDataByteSize];
        song->nextByteToRead += song->aspds[i].mDataByteSize;
    }
    
    ioData->mBuffers[0].mData = (void*)song->oneCallbackOfData.bytes;
    ioData->mBuffers[0].mDataByteSize = (UInt32)song->oneCallbackOfData.length;
    
    *outDataPacketDescription = song->aspds;
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
