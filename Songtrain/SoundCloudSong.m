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
    
    BOOL setOutputASBD, readyWithPackets, startedArtworkDownLoad, finishedLoading;
    
    NSInputStream *musicStream;
    
    NSUInteger nextByteToRead;
    NSURLConnection *artworkConnection;
    NSMutableData *imageData;
}

- (instancetype)initWithURL:(NSURL *)url andPeer:(MCPeerID*)peer {
    if (self = [super init]) {
        self.url = url;
        self.peer = peer;
        songData = nil;
        setOutputASBD = readyWithPackets = startedArtworkDownLoad = finishedLoading = NO;
        nextByteToRead = 0;
        converter = NULL;
        filestream = NULL;
    }
    return self;
}

-(instancetype)initWithSoundCloudDictionary:(NSDictionary*)dic andPeer:(MCPeerID*)peer {
    if (self = [self initWithURL:[NSURL URLWithString:dic[@"uri"]] andPeer:peer]) {
        
        self.title = dic[@"title"];
        self.artistName = dic[@"user"][@"username"];
        self.songLength = [dic[@"duration"] floatValue] / 1000.0;
        self.musicURL = [NSURL URLWithString:dic[@"stream_url"]];
        
        NSString *artwork = dic[@"artwork_url"];
        
        if ([artwork isKindOfClass:[NSString class]] == YES) {
            artwork = [artwork stringByReplacingOccurrencesOfString:@"large" withString:@"t500x500"];
            self.artworkURL = [NSURL URLWithString:artwork];
        } else if ([dic[@"user"][@"avatar_url"] isKindOfClass:[NSString class]] == YES) {
            artwork = [dic[@"user"][@"avatar_url"] stringByReplacingOccurrencesOfString:@"large" withString:@"t500x500"];
            self.artworkURL = [NSURL URLWithString:artwork];
        }
        
        NSLog(@"Creating SoundCloudSong from: %@", dic);
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        setOutputASBD = [aDecoder decodeBoolForKey:@"setOASBD"];
        self.musicURL = [aDecoder decodeObjectForKey:@"musicURL"];
        self.artworkURL = [aDecoder decodeObjectForKey:@"artworkURL"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.musicURL forKey:@"musicURL"];
    [aCoder encodeObject:self.artworkURL forKey:@"artworkURL"];
    [aCoder encodeBool:setOutputASBD forKey:@"setOASBD"];
}

-(void)setInputASBDBecauseICantReachItAnotherWay {
    self.inputASDBIsSet = YES;
    NSLog(@"set inputASBD");
}

-(void)initSoundCloudConverter {
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
    [self initSoundCloudConverter];
}

-(void)prepareSong {
    NSLog(@"Is remote song: %@, peer is %@", self.remoteSong ? @"YES" : @"NO", self.peer);
    if (self.remoteSong) {
        [super prepareSong];
        return;
    }
    
    NSLog(@"preparing SoundCloudSong");
    
    __weak SoundCloudSong *weakSelf = self;
    OSStatus error = AudioFileStreamOpen((__bridge void*)weakSelf, fileStreamPropertyCallback, fileStreamDataCallback, kAudioFileMP3Type, &filestream);
    if (error) {
        char errorString[7];
        FormatError(errorString, error);
        NSLog(@"Error opening file stream: %s\n", errorString);
    }
    
    [self requestSongData];
    
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

    if (connection == artworkConnection) {
        [imageData appendData:data];
        return;
    }
    
    OSStatus error = AudioFileStreamParseBytes(filestream, (UInt32)data.length, data.bytes, 0);
    
    if (error) {
        char errorString[7];
        FormatError(errorString, error);
        NSLog(@"Error in stream parsing bytes: %s\n", errorString);
    }
    
    if (startedArtworkDownLoad == NO) {
        imageData = [[NSMutableData alloc] init];
        artworkConnection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:self.artworkURL] delegate:self];
        startedArtworkDownLoad = YES;
    }
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (connection == artworkConnection) {
        [self willChangeValueForKey:@"albumImage"];
        image = [UIImage imageWithData:imageData];
        [self didChangeValueForKey:@"albumImage"];
        imageData = nil;
        return;
    }
    
    finishedLoading = YES;
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
        [song initSoundCloudConverter];
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
        [song->songData appendBytes:&inPacketDescriptions[i] length:sizeof(AudioStreamPacketDescription)];
        [song->songData appendBytes:inInputData + inPacketDescriptions[i].mStartOffset length:inPacketDescriptions[i].mDataByteSize];
    }
    //NSLog(@"songData is now %lu long", (unsigned long)song->songData.length);
}

#pragma mark Music Methods

-(NSData *)getNextPacketofMaxBytes:(NSInteger)maxBytes {
    NSUInteger len = MUSIC_PACKET_SIZE;
    NSLog(@"len = %lu", (unsigned long)len);
    if (len > maxBytes) {
        len = maxBytes;
        NSLog(@"len(maxBytes) = %lu", (unsigned long)len);
    }
    if (len > songData.length - nextByteToRead) {
        len = songData.length - nextByteToRead;
        NSLog(@"len(songData.length) = %lu", (unsigned long)len);
    }
    
    NSLog(@"Next byte %lu maxBytes: %lu songData.length: %lu", (unsigned long)nextByteToRead, (long)maxBytes, (unsigned long)songData.length);
    NSRange range = NSMakeRange(nextByteToRead, len);
    nextByteToRead += len;
    NSLog(@"Sent %lu bytes", (unsigned long)len);
    
    if (finishedLoading == YES && nextByteToRead == songData.length) {
        self.isFinishedSendingSong = YES;
    }
    return len == 0 ? nil : [songData subdataWithRange:range];
}

- (int)getMusicPackets:(UInt32*)numOfPackets forBuffer:(AudioBufferList*)ioData
{
    if (self.remoteSong) {
        return [super getMusicPackets:numOfPackets forBuffer:ioData];
    }
    
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
    //if (song->nextByteToRead >= song->songData.length && song->nextByteToRead > song->estimatedSize) {
    if (song->finishedLoading == YES && song->nextByteToRead == song->songData.length) {
        return -2;
    }
    
    song->oneCallbackOfData.length = 0;
    
    for (int i = 0; i < *ioNumberDataPackets; i++) {
        
        CFDataRef songData = (__bridge CFDataRef)song->songData;
        
        NSUInteger length = song->songData.length;
        NSUInteger nextbyte = song->nextByteToRead;
        
        if (length - nextbyte <= sizeof(AudioStreamPacketDescription)) {
            break;
        }
        
        AudioStreamPacketDescription aspd;
        CFDataGetBytes(songData, CFRangeMake(nextbyte, sizeof(AudioStreamPacketDescription)), (UInt8*)&aspd);
        
        if (aspd.mDataByteSize > length - nextbyte - sizeof(AudioStreamPacketDescription)) {
            break;
        }
        
        memcpy(&song->aspds[i], &aspd, sizeof(AudioStreamPacketDescription));
        song->aspds[i].mStartOffset = song->oneCallbackOfData.length;
        song->nextByteToRead += sizeof(AudioStreamPacketDescription);
        
        UInt8 *tempBuff = malloc(aspd.mDataByteSize);
        CFDataGetBytes(songData, CFRangeMake(song->nextByteToRead, song->aspds[i].mDataByteSize), tempBuff);
        
        [song->oneCallbackOfData appendBytes:tempBuff length:song->aspds[i].mDataByteSize];
        song->nextByteToRead += song->aspds[i].mDataByteSize;
        
        free(tempBuff);
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

- (UIImage*)getAlbumImage
{
    if (self.remoteSong) {
        return [super getAlbumImage];
    }
    return image;
}

-(void)dealloc {
    songData = nil;
    oneCallbackOfData = nil;
    musicStream = nil;
    artworkConnection = nil;
    imageData = nil;
    
    if (converter) {
        AudioConverterDispose(converter);
    }
    
    if (filestream) {
        AudioFileStreamClose(filestream);
    }
}

@end
