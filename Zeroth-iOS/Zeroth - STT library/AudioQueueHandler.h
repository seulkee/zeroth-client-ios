//
//  AudioQueueHandler.h
//  Zeroth-iOS
//
//  Created by Bryan S. Kim
//  Copyright © 2019 Atlas Guide. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioQueue.h>

#define NUM_BUFFERS 3
#define kAudioConverterPropertyMaximumOutputPacketSize		'xops'

typedef struct HandlerState {
		AudioFileID                 audioFile;
		AudioStreamBasicDescription dataFormat;
		AudioQueueRef               queue;
		AudioQueueBufferRef         buffers[NUM_BUFFERS];
		UInt32                      bufferByteSize; 
		SInt64                      currentPacket;
		BOOL                        listening;
	} HandlerState;


@protocol AudioQueueHandlerDelegate <NSObject>

@optional
-(void)audioQueueHandlerPassData:(NSData *)bufferData;
@end

@interface AudioQueueHandler : NSObject

@property (nonatomic, weak) id<AudioQueueHandlerDelegate> delegate;
@property (nonatomic, readonly) BOOL isListening;
@property (atomic) double sampleRate;

- (BOOL)startListening;
- (BOOL)startListeningAtSampleRate:(float)sampleRate;
- (void)stopListening;

@end
