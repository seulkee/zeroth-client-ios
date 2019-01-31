# Zeroth Speech-To-Text library for iOS 

**Zeroth** was initially developed as part of Atlas’s **Conversational AI platform**, which enables enterprises to add analysis and intelligence to their conversational data. Visit our [homepage](https://zeroth-cloud.goodatlas.com/) for more information.

We now introduce Zeroth Cloud as a hosted service for any developer to incorporate speech-to-text into his or her service*.*

We'd love to hear from you! Please email us at [`support@goodatlas.com`](mailto:support@goodatlas.com) with any questions, suggestions or requests.



## Features

- Real time speech-to-text
- Change sample rate between 16000 and 44100



## Requirements

- iOS 10.0+
- Xcode 10.0+

  

## Usage

First thing is to import the header file. See the Installation instructions on how to add Zeroth to your project.

```objc
#import "ZerothSpeechToText.h"
```

Once imported, you can create a connection to zeroth WebSocket server with your authentication info. Set  the delegate as well.

```objc
self.zeroth = [ZerothSpeechToText new];
self.zeroth.delegate = self;

// setup authentication
[self.zeroth setupAuthenticationAppID:@"ENTER_YOUR_APP_ID"
                            AppSecret:@"ENTER_YOUR_APP_SECRET"
                             Language:zKorean 	//"zKorea" or "zEnglish"
                            FinalOnly:NO];
// connect to zeroth STT server 
[self.zeroth connectZerothSocket];
```

After you are connected, there are some delegate methods that we need to implement.

### zerothSocketDidConnect

```objc
- (void)zerothSocketDidConnect {
    NSLog(@"socket is connected");
}
```

### zerothSocketDidDisconnectWithError

```objc
- (void)zerothSocketDidDisconnectWithError:(NSError*)error {
    NSLog(@"zeroth socket is disconnected: %@", [error localizedDescription]);
}
```

### zerothSocketDidReceiveMessage

```objc
- (void)zerothSocketDidReceiveMessage:(NSString*)string {
    NSLog(@"got some received zeroth result in json: %@", string);
}
```

### zerothSocketDidReceiveData

```objc
-(void)zerothSocketDidReceiveData:(NSData*)data {
    NSLog(@"got some binary data: %d",data.length);
}
```

The delegate methods give you a simple way to handle data from the server while the socket activities are occured.  

### connectZerothSocket

```objc
[self.zeroth connectZerothSocket]; // create connection to zeroth server
```

### disconnectZerothSocket

```objc
[self.zeroth disconnectZerothSocket]; // disconnect from zeroth server
```

### startZerothSTT

```objc
[self.zeroth startZerothSTT]; // start listening from mic and send buffer to zeroth server 
```

### stopZerothSTT

```objc
[self.zeroth stopZerothSTT]; // stop listening and disconnect zeroth socket 
```



## Example Project

Check out the project to see how to setup a connection to Zeroth server and stream to real time audio.



## Dependency Management & Instructions

- The recommended approach for installing Zeroth is via the CocoaPods package manager (like most libraries). Create empty `Podfile` or use command `pod init` to generate default `Podfile` Then add following pod info.

  ```
  pod 'zeroth'
  pod 'jetfire', :inhibit_warnings => true
  ```

- Remember to modify the .plist file to get user's authorization for using the microphone, of course the `<String>` value must be customized to your needs, you can do this by creating and modifying the values in the `Property List` or right-click on the `.plist` file and `Open As` -> `Source Code` and paste the following lines before the `</dict>` tag.

  ```
  <key>NSMicrophoneUsageDescription</key>
  <string>Your microphone will be used to analyze voice data </string>
  ```

- Create developer account and generate AppID and AppSecret - the app credential at https://zeroth-console.goodatlas.com 

- Connect UI and create simple functional logics  

- In order to be able to run project, you need to have iOS 10.0+.

- **Build and Run the app!**

- More detailed instructions in the code comments.



## Dependencies

- Jetfire - WebSocket (RFC 6455) client library for iOS & OS X

  

## License

Zeroth for iOS is license under the Apache License.



## Version History

0.1.0 First public version



Copyright © 2019 Atlas Guide. All rights reserved.
