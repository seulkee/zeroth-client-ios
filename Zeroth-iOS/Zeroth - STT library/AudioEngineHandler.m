//
//  AudioEngineHandler.m
//  Zeroth-iOS
//
//  Created by Bryan S. Kim
//  Copyright © 2019 Atlas Guide. All rights reserved.
//

#import "AudioEngineHandler.h"
#import <AVFoundation/AVFoundation.h>

@interface AudioEngineHandler () {
    AVAudioEngine *audioEngine;
}

@end

@implementation AudioEngineHandler

// Initialize AudioEngineHandler
- (id) init {
    if (self = [super init]) {
        //variable initialize
        self.sampleRate = 11025;
    }
    return self;
}

- (NSData *)bufferToNSData:(AVAudioPCMBuffer *)buffer {
    //return [[NSData alloc] initWithBytes:buffer.floatChannelData[0] length:buffer.frameLength * 4];
    return [[NSData alloc] initWithBytes:buffer.int16ChannelData[0] length:buffer.frameLength * 2];
}

// Starts listening and recognizing user input through the phone's microphone
- (void)startListening {
    
    // Initialize the AVAudioEngine
    audioEngine = [[AVAudioEngine alloc] init];
    
    // Starts an AVAudio Session
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    [audioSession setMode:AVAudioSessionModeSpokenAudio error:&error];
//    [audioSession setPreferredSampleRate:self.sampleRate error:&error];
    
    // Sets the recording format - live downsample buffer
    // iOS default AVAudioEngine sample rate - AVAudioPCMFormatFloat32 / sampleRate : 44100 / channels : 2 / interleaved : NO
    //           zeroth required sample rate - AVAudioPCMFormatInt16   / sampleRate : 44100 / channels : 1 / interleaved : YES
    AVAudioMixerNode *downSampleMixerNode = [[AVAudioMixerNode alloc] init];
    [audioEngine attachNode:downSampleMixerNode];
    
    AVAudioFormat *recordingFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16
                                                                      sampleRate:self.sampleRate
                                                                        channels:1
                                                                     interleaved:YES];
    
    // NOTE: AVAudioEngine only support only for multiple of 44100/4 as sample rate.
    //       due to such limitation, AudioQueue lower level APIs may need to be implemented
    
    [audioEngine connect:audioEngine.inputNode to:downSampleMixerNode format:[audioEngine.inputNode inputFormatForBus:0]];
    [audioEngine connect:downSampleMixerNode to:audioEngine.outputNode format:recordingFormat];
    
    [downSampleMixerNode installTapOnBus:0 bufferSize:1024*4 format:[downSampleMixerNode outputFormatForBus:0] block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        NSData *bufferData = [self bufferToNSData:buffer];
        if (self.delegate) {
            [self.delegate audioEngineHandlerPassData:bufferData];
        }
    }];
    
    // Starts the audio engine, i.e. it starts listening.
    [audioEngine prepare];
    [audioEngine startAndReturnError:&error];
    NSLog(@"I'm listening... say something...");
}

- (void)startListeningAtSampleRate:(float)sampleRate {
    self.sampleRate = sampleRate;
    [self startListening];
}

- (void)stopListening {
    if (audioEngine.isRunning) {
        [audioEngine stop];
        [audioEngine.inputNode removeTapOnBus:0];
    }
}

- (BOOL)isRunning {
    return audioEngine.isRunning;
}

@end
