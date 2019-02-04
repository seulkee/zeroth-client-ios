//
//  ViewController.m
//  Zeroth-iOS
//
//  Created by Bryan S. Kim
//  Copyright © 2019 Atlas Guide. All rights reserved.
//

#import "ViewController.h"
#import "ZerothSpeechToText.h"

@interface ViewController () <ZerothSTTDelegate> {
    
}
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toggleStartEndSTT;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toggleConnectionStatus;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sampleRateSegControl;
@property (strong, nonatomic) NSString *partialStr;
@property (strong, nonatomic) NSString *fullHistoryStr;

@property (strong, nonatomic) ZerothSpeechToText *zeroth;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.zeroth = [ZerothSpeechToText new];
    self.zeroth.delegate = self;

    // setup sample rate (optional) - default 16 KHz
    [self.zeroth setupSampleRate:z16000];
    
    // setup buffer size in second (optional) - default 250 ms
    [self.zeroth setupBufferSizeInSecond:0.25];
    
    // setup authentication
    [self.zeroth setupAuthenticationAppID:@"ENTER_YOUR_APP_ID"
                                AppSecret:@"ENTER_YOUR_APP_SECRET"
                                 Language:zKorean //"zKorea" or "zEnglish"
                                FinalOnly:NO];
    // connect to zeroth STT server
    [self.zeroth connectZerothSocket];
}

- (void)viewWillAppear:(BOOL)animated {
    [self setupDefaultUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupDefaultUI {
    [_sampleRateSegControl setTitle:@"44100.0" forSegmentAtIndex:0];
    [_sampleRateSegControl setTitle:@"16000.0" forSegmentAtIndex:1];
    
    [_sampleRateSegControl setSelectedSegmentIndex:1];
}

- (NSDictionary *)simpleJSONparserInDictionary:(NSString *)jsonString {
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    if (YES == [json isKindOfClass:[NSDictionary class]]) {
        return json;
    }
    
    return [NSDictionary new];
}

- (void)resetTextView {
    _fullHistoryStr = @"";
    _logTextView.text = _fullHistoryStr;
}

- (void)updateTextView:(NSString *)jsonString {
    
    NSDictionary *resultDict = [self simpleJSONparserInDictionary:jsonString];
    
    _partialStr = resultDict[@"transcript"];
    _logTextView.text = [(0 == _fullHistoryStr.length) ? _fullHistoryStr : [_fullHistoryStr stringByAppendingString:@"\n"] stringByAppendingString:_partialStr];

    if ([resultDict[@"final"] isEqual:@(YES)]) {
        _fullHistoryStr = _logTextView.text;
    }

    [self scrollTextViewToBottom:self.logTextView];
}

- (void)scrollTextViewToBottom:(UITextView *)textView {
    
    if (textView.text.length > 0) {
        NSRange bottom = NSMakeRange(textView.text.length -1, 1);
        [textView scrollRangeToVisible:bottom];
    }
}

#pragma mark - ZerothSTTDelegate methods

- (void)zerothSocketDidConnect {
    NSLog(@"zeroth socket is connected");
    self.toggleConnectionStatus.title = @"Disconnect";
    
    [self resetTextView];
    [self disableSampleRateSegControl];
    [self disableConnectionButton];
    [self enableStartSTTButton];
}

- (void)zerothSocketDidDisconnectWithError:(NSError*)error {
    NSLog(@"zeroth socket is disconnected: %@", [error localizedDescription]);
    self.toggleConnectionStatus.title = @"Connect";
    
    //make sure all connection and microphone off
    [self resetAllSetting];
    [self enableSampleRateSegControl];
    [self enableConnectionButton];
    [self disableStartSTTButton];
}

- (void)zerothSocketDidReceiveMessage:(NSString*)string {
    NSLog(@"result: %@", string);

    [self updateTextView:string];
}

-(void)zerothSocketDidReceiveData:(NSData*)data {
    NSLog(@"got some binary data: %lu",(unsigned long)data.length);
}

- (void)resetAllSetting {
    
    //reset listening - turn off microphone
    if ([_zeroth isListening]) {
        [_zeroth stopZerothSTT];
        self.toggleStartEndSTT.title = @"Start";
    }
    
    //reset websocket
    if(_zeroth.isConnected) {
        [_zeroth disconnectZerothSocket];
        self.toggleConnectionStatus.title = @"Connect";
    }
}

#pragma mark - IB target actions
- (IBAction)toggleStartSTT:(UIBarButtonItem *)sender {
    
    if ([_zeroth isListening]) {
        [_zeroth stopZerothSTT];
        sender.title = @"Start";
    } else {
        [_zeroth startZerothSTT];
        sender.title = @"End";
    }
}

- (IBAction)toggleSocketConnect:(UIBarButtonItem *)sender {
    
    if(_zeroth.isConnected) {
        [_zeroth disconnectZerothSocket];
        sender.title = @"Connect";
    } else {
        [_zeroth connectZerothSocket];
        sender.title = @"Disconnect";
    }
}

- (IBAction)changeSampleRates:(id)sender {
    
    if(_sampleRateSegControl.selectedSegmentIndex == 0) {
        [_zeroth setupSampleRate:z44100];
    }
    else if (_sampleRateSegControl.selectedSegmentIndex == 1) {
        [_zeroth setupSampleRate:z16000];
    }
}

- (void)disableSampleRateSegControl {
    _sampleRateSegControl.enabled = NO;
}

- (void)enableSampleRateSegControl {
    _sampleRateSegControl.enabled = YES;
}

- (void)disableConnectionButton {
    _toggleConnectionStatus.enabled = NO;
}

- (void)enableConnectionButton {
    _toggleConnectionStatus.enabled = YES;
}

- (void)disableStartSTTButton {
    _toggleStartEndSTT.enabled = NO;
}

- (void)enableStartSTTButton {
    _toggleStartEndSTT.enabled = YES;
}

@end
