//
//  AudioEngineHandler.h
//  Zeroth-iOS
//
//  Created by Bryan S. Kim
//  Copyright © 2019 Atlas Guide. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AudioEngineHandlerDelegate <NSObject>

@optional
-(void)audioEngineHandlerPassData:(NSData *)bufferData;
@end

@interface AudioEngineHandler : NSObject

@property (nonatomic, weak) id<AudioEngineHandlerDelegate> delegate;
@property (readonly, nonatomic, getter=isRunning) BOOL running;
@property (atomic) double sampleRate;

- (void)startListening;
- (void)startListeningAtSampleRate:(float)sampleRate;
- (void)stopListening;

@end
