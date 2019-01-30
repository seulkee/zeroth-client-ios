//
//  ZerothSpeechToText.m
//  Zeroth-iOS
//
//  Created by Bryan S. Kim
//  Copyright © 2019 Atlas Guide. All rights reserved.
//

#define USE_AUDIOENGINE 0

#import "ZerothSpeechToText.h"
#import "JFRWebSocket.h"
#import "AudioEngineHandler.h"
#import "AudioQueueHandler.h"
#import <AVFoundation/AVFoundation.h>

@interface ZerothSpeechToText ()<NSURLSessionDelegate, JFRWebSocketDelegate, AudioEngineHandlerDelegate, AudioQueueHandlerDelegate> {
    
}

@property(nonatomic, strong)JFRWebSocket *socket;
#if USE_AUDIOENGINE
@property(nonatomic, strong)AudioEngineHandler *audioEngineHandler;
#else
@property(nonatomic, strong)AudioQueueHandler *audioQueueHandler;
#endif

@property(nonatomic, strong)NSString *access_token;
@property(nonatomic, strong)NSString *appID;
@property(nonatomic, strong)NSString *appSecret;
@property(nonatomic, strong)NSString *language;
@property(nonatomic, strong)NSString *finalOnly;

@end

@implementation ZerothSpeechToText

- (instancetype)init {
    if(self = [super init]) {
        
#if USE_AUDIOENGINE
        self.sampleRate = 11025;
        self.audioEngineHandler = [[AudioEngineHandler alloc] init];
        self.audioEngineHandler.delegate = self;
#else
        self.sampleRate = 16000;
        self.audioQueueHandler = [[AudioQueueHandler alloc] init];
        self.audioQueueHandler.delegate = self;
#endif
    }
    
    return self;
}

- (void)authenticationRequestAppID:(NSString *)appID
                         AppSecret:(NSString *)appSecret
                          Language:(NSString *)language
                         FinalOnly:(BOOL)isFinalOnly {
    
    [self authenticationRequest:appID withAppSecret:appSecret];
    self.language = language;
    self.finalOnly = isFinalOnly ? @"true" : @"false";
    
    [self authenticationRequest:nil];
}

- (void)authenticationRequest:(NSString *)appID
                withAppSecret:(NSString *)appSecret {
    
    self.appID = appID;
    self.appSecret = appSecret;
}

- (void)authenticationRequest:(id)sender {
    
    NSString *authorizationStr = [NSString stringWithFormat:@"%@:%@", self.appID, self.appSecret];
    /* Configure session, choose between:
     * defaultSessionConfiguration
     * ephemeralSessionConfiguration
     * backgroundSessionConfigurationWithIdentifier:
     And set session-wide properties, such as: HTTPAdditionalHeaders,
     HTTPCookieAcceptPolicy, requestCachePolicy or timeoutIntervalForRequest.
     */
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    // Create session, and optionally set a NSURLSessionDelegate.
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    
    // Create the Request:
    // Obtain an Access-Token (GET https://zeroth.goodatlas.com:2053/token)
    
    NSURL* URL = [NSURL URLWithString:@"https://zeroth.goodatlas.com:2053/token"];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"GET";
    
    // Headers
    [request addValue:authorizationStr forHTTPHeaderField:@"Authorization"];
    
    // Start a new Task
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            // Success
            NSLog(@"URL Session Task Succeeded: HTTP %ld", (long)((NSHTTPURLResponse*)response).statusCode);
            NSLog(@"%@", [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]);
            
            if (200 == ((NSHTTPURLResponse*)response).statusCode) {
                NSDictionary* json = [NSJSONSerialization
                                      JSONObjectWithData:data
                                      options:kNilOptions
                                      error:&error];
                
                NSLog(@"access_token = %@", json[@"access_token"]);
                self.access_token = json[@"access_token"];
                
                [self connectSocket];
                
            }
        }
        else {
            // Failure
            NSLog(@"URL Session Task Failed: %@", [error localizedDescription]);
        }
    }];
    [task resume];
    [session finishTasksAndInvalidate];
}


- (void)connectSocket {
    
    // Open a WebSocket connection
    // wss://zeroth.goodatlas.com:2087/client/ws/speech?access-token=<access-token>&language=<language>
    
    /* Available sample rates - minimum requirements
     16 KHz, Mono:
     audio/x-raw,+layout=(string)interleaved,+rate=(int)16000,+format=(string)S16LE,+channels=(int)1
     44 KHz, Mono:
     audio/x-raw,+layout=(string)interleaved,+rate=(int)44100,+format=(string)S16LE,+channels=(int)1
     */
    
    //NSString *urlStrin = [NSString stringWithFormat:@"wss://zeroth.goodatlas.com:2087/client/ws/speech?access-token=%@&language=%@&final-only=false&content-type=audio/x-raw,+layout=(string)interleaved,+rate=(int)44100,+format=(string)S16LE,+channels=(int)1", self.access_token, language];
    
    NSString *sampleRateStr = [NSString stringWithFormat:@"%.0f", self.sampleRate];
    NSString *urlStrin = [NSString stringWithFormat:@"wss://zeroth.goodatlas.com:2087/client/ws/speech?access-token=%@&language=%@&final-only=%@&content-type=audio/x-raw,+layout=(string)interleaved,+rate=(int)%@,+format=(string)S16LE,+channels=(int)1", self.access_token, self.language, self.finalOnly, sampleRateStr];
    self.socket = [[JFRWebSocket alloc] initWithURL:[NSURL URLWithString:urlStrin] protocols:@[@"chat",@"superchat"]];
    self.socket.delegate = self;
    [self.socket connect];
}

#pragma mark -

//- (void)accessSoundFileInNSData {
//
////    NSString *path = [pathURL filePath];
////    if([[NSFileManager defaultManager] fileExistsAtPath:path)
////    {
////        NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
////    }
////        else
////    {
////        NSLog(@"File not exits");
////    }
//    NSURL *imgPath = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"mp3"];
//    NSString *stringPath = [imgPath absoluteString]; //this is correct
//    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:stringPath]];
//
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSArray *tableArray = [self listFileAtPath:documentsDirectory];
//
//    NSLog(@"%@ - %@", tableArray, stringPath);
//}


-(NSArray *)listFileAtPath:(NSString *)path {
    
    NSLog(@"list all files found");
    
    int count;
    
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    for (count = 0; count < (int)[directoryContent count]; count++)
    {
        NSLog(@"File %d: %@", (count + 1), [directoryContent objectAtIndex:count]);
    }
    return directoryContent;
}

#if USE_AUDIOENGINE
#pragma mark - AudioEngineHandler Delegate methods
-(void)audioEngineHandlerPassData:(NSData *)bufferData {
    [self.socket writeData:bufferData];
}
#else
#pragma mark - AudioQueueHandler Delegate methods
-(void)audioQueueHandlerPassData:(NSData *)bufferData {
    [self.socket writeData:bufferData];
}
#endif

#pragma mark - WebSocket Delegate methods
-(void)websocketDidConnect:(JFRWebSocket*)socket {
    //NSLog(@"websocket is connected");
    [self.delegate zerothSocketDidConnect];
}

-(void)websocketDidDisconnect:(JFRWebSocket*)socket error:(NSError*)error {
    //NSLog(@"websocket is disconnected: %@", [error localizedDescription]);
    //        [self.socket connect];
    [self.delegate zerothSocketDidDisconnectWithError:error];
}

-(void)websocket:(JFRWebSocket*)socket didReceiveMessage:(NSString*)string {
    //NSLog(@"Received text: %@", string);
    [self.delegate zerothSocketDidReceiveMessage:string];
}

-(void)websocket:(JFRWebSocket*)socket didReceiveData:(NSData*)data {
    //NSLog(@"Received data: %@", data);
    [self.delegate zerothSocketDidReceiveData:data];
}

- (void)sendSampleRawAudio {
    NSURL *imgPath = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"mp3"];
    NSString *stringPath = [imgPath absoluteString]; //this is correct
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:stringPath]];
    
    [self.socket writeData:data];
}

#if USE_AUDIOENGINE
- (BOOL)isListening {
    return self.audioEngineHandler.isRunning;
}
#else
- (BOOL)isListening {
    return self.audioQueueHandler.isListening;
}
#endif

- (BOOL)isConnected {
    return self.socket.isConnected;
}

- (void)zerothSTTStart {
    NSLog(@"microphone on");
#if USE_AUDIOENGINE
    [self.audioEngineHandler startListeningAtSampleRate:self.sampleRate];
#else
    [self.audioQueueHandler startListeningAtSampleRate:self.sampleRate];
#endif
    
    
}

- (void)zerothSTTEnd {
    NSLog(@"microphone off");
#if USE_AUDIOENGINE
    [self.audioEngineHandler stopListening];
#else
    [self.audioQueueHandler stopListening];
#endif
    [self.socket writeString:@"\'EOS\'"];
}

- (void)toggleSocketConnection {
    if(self.socket.isConnected) {
        NSLog(@"socket will be disconnected");
        [self.socket disconnect];
    } else {
        NSLog(@"socket will be connected");
        [self authenticationRequest:nil];
    }
}

- (void)zerothSocketDisconnect {
    [self.socket disconnect];
}

- (void)zerothSocketReconnect {
    
    if (!_appID || !_appSecret || !_language) {
        
        if (!_appID) {
            NSLog(@"unable to reconnect - check appID");
        } else if (!_appSecret) {
            NSLog(@"unable to reconnect - check appSecret");
        } else if (!_language) {
            NSLog(@"unable to reconnect - check language");
        } else {
            NSLog(@"unable to reconnect");
        }
    }
    else {
        [self authenticationRequest:nil];
    }
}

@end