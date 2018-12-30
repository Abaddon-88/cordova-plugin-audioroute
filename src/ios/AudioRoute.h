#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>

@interface AudioRoute :CDVPlugin {
    NSString* callbackId;
}

- (void) start:(CDVInvokedUrlCommand*)command;
- (void) stop:(CDVInvokedUrlCommand*)command;
- (void) currentOutputs:(CDVInvokedUrlCommand*)command;
- (void) overrideOutput:(CDVInvokedUrlCommand*)command;
- (void) setRouteChangeCallback:(CDVInvokedUrlCommand*)command;
- (void) startProximitySensor:(CDVInvokedUrlCommand*)command;

@end
