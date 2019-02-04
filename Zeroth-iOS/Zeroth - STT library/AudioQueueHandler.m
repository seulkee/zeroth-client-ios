//
//  AudioQueueHandler.m
//  Zeroth-iOS
//
//  Created by Bryan S. Kim
//  Copyright © 2019 Atlas Guide. All rights reserved.
//

#import "AudioQueueHandler.h"

@interface AudioQueueHandler()

@property (nonatomic, assign) HandlerState handlerState;
@property (atomic) UInt32 bufferByteSize;

@end

@implementation AudioQueueHandler

// Initialize AudioQueueHandler
- (id)init {
    if (self = [super init]) {
        _handlerState.listening = NO;
        if (!self.sampleRate) {
            self.sampleRate = 16000;
        }
        if (!self.bufferSizeInSec) {
            self.bufferSizeInSec = 0.25; // default buffer chunk in second is 250 ms 
        }
        
    }
    return self;
}

// Set up the audio format
- (void)setupAudioFormat:(AudioStreamBasicDescription*)format {
    format->mSampleRate = self.sampleRate;
    format->mFormatID = kAudioFormatLinearPCM;
    format->mFormatFlags = kLinearPCMFormatFlagIsNonInterleaved |  kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked; 
    format->mChannelsPerFrame = 1; // mono
    format->mBitsPerChannel = 16; 
    format->mFramesPerPacket = 1;
    format->mBytesPerPacket = 2; 
    format->mBytesPerFrame = 2;
    format->mReserved = 0;
}

- (BOOL)startListening {
    // file url
    [self setupAudioFormat:&_handlerState.dataFormat];
    
    // new input queue
    OSStatus status;
    status = AudioQueueNewInput(&_handlerState.dataFormat, HandleInputBuffer, (__bridge void*)self, CFRunLoopGetCurrent(),kCFRunLoopCommonModes, 0, &_handlerState.queue);
    
    // figure out the buffer size 
    DeriveBufferSize(_handlerState.queue, _handlerState.dataFormat, _bufferSizeInSec, &_handlerState.bufferByteSize);
    _bufferByteSize = _handlerState.bufferByteSize;
    
    // allocate those buffers and enqueue them
    for(int i = 0; i < NUM_BUFFERS; i++) {
        status = AudioQueueAllocateBuffer(_handlerState.queue, _handlerState.bufferByteSize, &_handlerState.buffers[i]);
        if (status) {fprintf(stderr, "Error allocating buffer %d\n", i); return NO;}
        
        status = AudioQueueEnqueueBuffer(_handlerState.queue, _handlerState.buffers[i], 0, NULL);
        if (status) {fprintf(stderr, "Error enqueuing buffer %d\n", i); return NO;}
    }
    
    // start listening
    status = AudioQueueStart(_handlerState.queue, NULL);
    if (status) {fprintf(stderr, "Could not start Audio Queue\n"); return NO;}
    _handlerState.currentPacket = 0;
    _handlerState.listening = YES;
    return YES;
}

- (BOOL)startListeningAtSampleRate:(float)sampleRate {
    
    self.sampleRate = sampleRate;
    return [self startListening];
}

// There's generally about a one-second delay before the buffers fully empty
- (void)reallyStopListening {
    AudioQueueFlush(_handlerState.queue);
    AudioQueueStop(_handlerState.queue, NO);
    _handlerState.listening = NO;
    
    for(int i = 0; i < NUM_BUFFERS; i++)
		AudioQueueFreeBuffer(_handlerState.queue, _handlerState.buffers[i]);
 
    AudioQueueDispose(_handlerState.queue, YES);
    AudioFileClose(_handlerState.audioFile);
}

// Stop the listening after waiting just a second
- (void)stopListening {
    [self performSelector:@selector(reallyStopListening) withObject:NULL afterDelay:1.0f];
}

// Return whether the listening is active
- (BOOL)isListening {
    return _handlerState.listening;
}

// Derive the Buffer Size. I punt with the max buffer size.
void DeriveBufferSize (AudioQueueRef audioQueue, AudioStreamBasicDescription ASBDescription, Float64 seconds, UInt32 *outBufferSize) {
    static const int maxBufferSize = 0x50000; // punting with 50k
    int maxPacketSize = ASBDescription.mBytesPerPacket;
    if (maxPacketSize == 0) {
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty(audioQueue, kAudioConverterPropertyMaximumOutputPacketSize, &maxPacketSize, &maxVBRPacketSize);
    }
    
    Float64 numBytesForTime = ASBDescription.mSampleRate * maxPacketSize * seconds;
    *outBufferSize = (UInt32)((numBytesForTime < maxBufferSize) ? numBytesForTime : maxBufferSize);
}

// Handle new input
static void HandleInputBuffer (void *aqData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime,
                               UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc) {
    AudioQueueHandler *audioQueueHandler = (__bridge AudioQueueHandler *)(aqData);
    
    // convert buffer to byte
    NSData *bufferData = [[NSData alloc] initWithBytes:inBuffer->mAudioData length:audioQueueHandler.bufferByteSize];
    
    // NOTE : bitrate = bitsPerSample * samplesPerSecond * channels
    //       for 16.0K
    //            16 * 16000 * 1 = 256000  ==>  256,000 bps or bitsPerSecond
    //            256000 bps / 8 bits = 32000  ==>  32,000 Bps or bytePerSecond (1 Byte = 8 bits)
    //            250 ms = 1/4 sec ==> So 32,000 Byte / 4 = 8,000 Byte
    //
    //       for 44.1K
    //            16 * 44100 * 1 = 705,600 bitsPerSecond
    //            705600 bps / 8 bits  ==> 88200 Bps
    //            250 ms = 1/4 sec ==> So 88,200 Byte / 4 = 22,050 Byte
    //
    // NSLog(@"----- data size：%ld", bufferData.length);
    
    if (audioQueueHandler.delegate && [audioQueueHandler.delegate respondsToSelector:@selector(audioQueueHandlerPassData:)]) {
        [audioQueueHandler.delegate audioQueueHandlerPassData:bufferData];
    }
    
    HandlerState *audioQueueData = &audioQueueHandler->_handlerState;
    AudioQueueEnqueueBuffer(audioQueueData->queue,
                            inBuffer,
                            0,
                            NULL);
    
}

@end
