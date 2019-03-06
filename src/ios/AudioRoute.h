#import <AVFoundation/AVFoundation.h>
#import <Cordova/CDV.h>

@interface AudioRoute :CDVPlugin {
    NSString* callbackId;
}

- (void) start:(CDVInvokedUrlCommand*)command;
- (void) stop:(CDVInvokedUrlCommand*)command;
- (void) currentOutputs:(CDVInvokedUrlCommand*)command;
- (void) overrideOutput:(CDVInvokedUrlCommand*)command;
- (void) setAudioMode:(CDVInvokedUrlCommand*)command;
- (void) setRouteChangeCallback:(CDVInvokedUrlCommand*)command;

@end
