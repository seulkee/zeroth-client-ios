//
//  ZerothSpeechToText.h
//  Zeroth-iOS
//
//  Created by Bryan S. Kim
//  Copyright © 2019 Atlas Guide. All rights reserved.
//
 
#import <Foundation/Foundation.h>

@protocol ZerothSTTDelegate <NSObject>
@optional
-(void)zerothSocketDidConnect;
-(void)zerothSocketDidDisconnectWithError:(nullable NSError*)error;
-(void)zerothSocketDidReceiveMessage:(nonnull NSString*)string;
-(void)zerothSocketDidReceiveData:(nullable NSData*)data;

@end

@interface ZerothSpeechToText : NSObject

@property (readonly, nonatomic, getter=isListening) BOOL listening;
@property (readonly, nonatomic, getter=isConnected) BOOL connected;
@property (atomic) double sampleRate;

@property (nonatomic, weak) id<ZerothSTTDelegate> delegate;

// Check list
// "Privacy - Microphone Usage Description" need to added in app plist 
// <key>NSMicrophoneUsageDescription</key>
// <string>The app needs microphone input to perform. </string>

// Parameters
// {
//    appId: string, // Required. You can get your appId with create new application in zeroth-console
//    appSecret: string,// Required. You can get your appSecret with create new application in zeroth-console
//    finalOnly: boolean, // Optional(Default: false) If this is 'true', you will get only final results.
//    language: string // Required. You can choose 'eng' for English or 'kor' for Korean
// }

- (void)authenticationRequestAppID:(NSString *)appID
                         AppSecret:(NSString *)appSecret
                          Language:(NSString *)language
                         FinalOnly:(BOOL)isFinalOnly;

- (void)zerothSTTStart;
- (void)zerothSTTEnd;

- (void)zerothSocketDisconnect;
- (void)zerothSocketReconnect;

@end


