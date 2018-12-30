#import "AudioRoute.h"

@implementation AudioRoute

NSString *const kLineOut         = @"line-out";
NSString *const kHeadphones      = @"headphones";
NSString *const kBluetoothA2DP   = @"bluetooth-a2dp";
NSString *const kBuiltinReceiver = @"builtin-receiver";
NSString *const kBuiltinSpeaker  = @"builtin-speaker";
NSString *const kHdmi            = @"hdmi";
NSString *const kAirPlay         = @"airplay";
NSString *const kBluetoothLE     = @"bluetooth-le";
NSString *const kUnknown         = @"unknown";

NSString *const kNewDeviceAvailable         = @"new-device-available";
NSString *const kOldDeviceUnavailable       = @"old-device-unavailable";
NSString *const kCategoryChange             = @"category-change";
NSString *const kOverride                   = @"override";
NSString *const kWakeFromSleep              = @"wake-from-sleep";
NSString *const kNoSuitableRouteForCategory = @"no-suitable-route-for-category";
NSString *const kRouteConfigurationChange   = @"route-config-change";

UIDevice *_currentDevice;
AVAudioSession *_audioSession;

BOOL _isProximityRegistered;
BOOL _proximityIsNear;

int _forceSpeakerOn;

NSString *_incallAudioMode;
NSString *_incallAudioCategory;
NSString *_origAudioCategory;
NSString *_origAudioMode;

NSString *_media;

id _proximityObserver;

- (void)pluginInitialize 
{
    NSLog(@"Initializing AudioRoute plugin");
    callbackId = nil;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                          selector:@selector(routeChange:)
                                          name:AVAudioSessionRouteChangeNotification
                                          object:nil];
    _currentDevice = [UIDevice currentDevice];
    _audioSession = [AVAudioSession sharedInstance];

    _isProximityRegistered = NO;
    _proximityIsNear = NO;

    _forceSpeakerOn = 0;

    _incallAudioMode = AVAudioSessionModeVoiceChat;
    _incallAudioCategory = AVAudioSessionCategoryPlayAndRecord;
    _origAudioCategory = nil;
    _origAudioMode = nil;

    _media = @"audio";

    _proximityObserver = nil;

    NSLog(@"AudioRoute plugin initialized");
}

- (void)routeChange:(NSNotification*)notification 
{
    NSLog(@"Audio device route changed!");
    if (callbackId != nil) {
        CDVPluginResult* pluginResult;
        NSString* reason;
        NSDictionary* dict = notification.userInfo;
        NSInteger routeChangeReason = [[dict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];

        switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            reason = kNewDeviceAvailable;
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            reason = kOldDeviceUnavailable;
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            reason = kCategoryChange;
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            reason = kOverride;
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            reason = kWakeFromSleep;
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            reason = kNoSuitableRouteForCategory;
            break;
        case AVAudioSessionRouteChangeReasonRouteConfigurationChange:
            reason = kRouteConfigurationChange;
            break;
        default:
            reason = kUnknown;
            break;
        }

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:reason];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }
}

- (void) setRouteChangeCallback:(CDVInvokedUrlCommand*)command 
{
    CDVPluginResult* pluginResult;
    callbackId = command.callbackId;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) currentOutputs:(CDVInvokedUrlCommand*)command 
{
    CDVPluginResult* pluginResult;
    NSMutableArray* outputs = [NSMutableArray array];

    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        NSString* portType = [desc portType];
        if ([portType isEqualToString:AVAudioSessionPortLineOut]) {
            [outputs addObject:kLineOut];
        } else if ([portType isEqualToString:AVAudioSessionPortHeadphones]) {
            [outputs addObject:kHeadphones];
        } else if ([portType isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
            [outputs addObject:kBluetoothA2DP];
        } else if ([portType isEqualToString:AVAudioSessionPortBuiltInReceiver]) {
            [outputs addObject:kBuiltinReceiver];
        } else if ([portType isEqualToString:AVAudioSessionPortBuiltInSpeaker]) {
            [outputs addObject:kBuiltinSpeaker];
        } else if ([portType isEqualToString:AVAudioSessionPortHDMI]) {
            [outputs addObject:kHdmi];
        } else if ([portType isEqualToString:AVAudioSessionPortAirPlay]) {
            [outputs addObject:kAirPlay];
        } else if ([portType isEqualToString:AVAudioSessionPortBluetoothLE]) {
            [outputs addObject:kBluetoothLE];
        } else {
            [outputs addObject:kUnknown];
        }
    }

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:[outputs copy]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) overrideOutput:(CDVInvokedUrlCommand*)command 
{
    CDVPluginResult* pluginResult;
    NSString* output = [command.arguments objectAtIndex:0];
    BOOL success;
    NSError* error;

    AVAudioSession* session = [AVAudioSession sharedInstance];

    // make sure the AVAudioSession is properly configured
    [session setActive: YES error: nil];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];

    if (output != nil) {
        if ([output isEqualToString:@"speaker"]) {
            success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
        } else {
            success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
        }
        if (success) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        }
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"'output' was null"];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void) setForceSpeakerphoneOn:(CDVInvokedUrlCommand*)command 
{
    int flag = [command.arguments objectAtIndex:0];
    _forceSpeakerOn = flag;
    NSLog(@"AudioRoute.setForceSpeakerphoneOn(): flag: %d", flag);

    int overrideAudioPort;
    NSString *overrideAudioPortString = @"";
    NSString *audioMode = @"";

    // --- WebRTC native code will change audio mode automatically when established.
    // --- It would have some race condition if we change audio mode with webrtc at the same time.
    // --- So we should not change audio mode as possible as we can. Only when default video call which wants to force speaker off.
    // --- audio: only override speaker on/off; video: should change category if needed and handle proximity sensor. ( because default proximity is off when video call )
    if (_forceSpeakerOn == 1) {
        // --- force ON, override speaker only, keep audio mode remain.
        overrideAudioPort = AVAudioSessionPortOverrideSpeaker;
        overrideAudioPortString = @".Speaker";
        if ([_media isEqualToString:@"video"]) {
            audioMode = AVAudioSessionModeVideoChat;
            [self stopProximitySensor];
        }
    } else if (_forceSpeakerOn == -1) {
        // --- force off
        overrideAudioPort = AVAudioSessionPortOverrideNone;
        overrideAudioPortString = @".None";
        if ([_media isEqualToString:@"video"]) {
            audioMode = AVAudioSessionModeVoiceChat;
            [self startProximitySensor];
        }
    } else { // use default behavior
        overrideAudioPort = AVAudioSessionPortOverrideNone;
        overrideAudioPortString = @".None";
        if ([_media isEqualToString:@"video"]) {
            audioMode = AVAudioSessionModeVideoChat;
            [self stopProximitySensor];
        }
    }

    BOOL isCurrentRouteToSpeaker;
    isCurrentRouteToSpeaker = [self checkAudioRoute:@[AVAudioSessionPortBuiltInSpeaker] routeType:@"output"];
    if ((overrideAudioPort == AVAudioSessionPortOverrideSpeaker && !isCurrentRouteToSpeaker)
            || (overrideAudioPort == AVAudioSessionPortOverrideNone && isCurrentRouteToSpeaker)) {
        @try {
            [_audioSession overrideOutputAudioPort:overrideAudioPort error:nil];
            NSLog(@"AudioRoute.setForceSpeakerphoneOn(): audioSession.overrideOutputAudioPort(%@) success", overrideAudioPortString);
        } @catch (NSException *e) {
            NSLog(@"AudioRoute.setForceSpeakerphoneOn(): audioSession.overrideOutputAudioPort(%@) fail: %@", overrideAudioPortString, e.reason);
        }
    } else {
        NSLog(@"AudioRoute.setForceSpeakerphoneOn(): did NOT overrideOutputAudioPort()");
    }

    if (audioMode.length > 0 && ![_audioSession.mode isEqualToString:audioMode]) {
        [self audioSessionSetMode:audioMode
                       callerMemo:NSStringFromSelector(_cmd)];
        NSLog(@"AudioRoute.setForceSpeakerphoneOn() audio mode has changed to %@", audioMode);
    } else {
        NSLog(@"AudioRoute.setForceSpeakerphoneOn() did NOT change audio mode");
    }
}

- (BOOL)checkAudioRoute:(NSArray<NSString *> *)targetPortTypeArray
              routeType:(NSString *)routeType
{
    AVAudioSessionRouteDescription *currentRoute = _audioSession.currentRoute;

    if (currentRoute != nil) {
        NSArray<AVAudioSessionPortDescription *> *routes = [routeType isEqualToString:@"input"]
            ? currentRoute.inputs
            : currentRoute.outputs;
        for (AVAudioSessionPortDescription *portDescription in routes) {
            if ([targetPortTypeArray containsObject:portDescription.portType]) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)startProximitySensor:(CDVInvokedUrlCommand*)command 
{
    if (_isProximityRegistered) {
        return;
    }

    NSLog(@"AudioRoute.startProximitySensor()");
    // _currentDevice.proximityMonitoringEnabled = YES;
    _currentDevice.proximityMonitoringEnabled = NO;

    CDVPluginResult* pluginResult;
    
    // --- in case it didn't deallocate when ViewDidUnload
    [self stopObserve:_proximityObserver
                 name:UIDeviceProximityStateDidChangeNotification
               object:nil];

    _proximityObserver = [self startObserve:UIDeviceProximityStateDidChangeNotification
                                     object:_currentDevice
                                      queue: nil
                                      block:^(NSNotification *notification) {
        BOOL state = _currentDevice.proximityState;
        if (state != _proximityIsNear) {
            NSLog(@"AudioRoute.UIDeviceProximityStateDidChangeNotification(): isNear: %@", state ? @"YES" : @"NO");
            _proximityIsNear = state;
            BOOL near = state ? YES : NO; 
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:near];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];

    _isProximityRegistered = YES;
}

- (void)stopProximitySensor
{
    if (!_isProximityRegistered) {
        return;
    }

    NSLog(@"AudioRoute.stopProximitySensor()");
    _currentDevice.proximityMonitoringEnabled = NO;

    // --- remove all no matter what object
    [self stopObserve:_proximityObserver
                 name:UIDeviceProximityStateDidChangeNotification
               object:nil];

    _isProximityRegistered = NO;
}

- (void)start:(CDVInvokedUrlCommand*)command
{
    NSString* mediaType = [command.arguments objectAtIndex:0];
    
    NSLog(@"AudioRoute.storeOriginalAudioSetup(): origAudioCategory=%@, origAudioMode=%@", _audioSession.category _audioSession.mode);
    _origAudioCategory = _audioSession.category;
    _origAudioMode = _audioSession.mode;

    _media = mediaType;

    if ([_media isEqualToString:@"video"]) {
        _incallAudioMode = AVAudioSessionModeVideoChat;
    } else {
        _incallAudioMode = AVAudioSessionModeVoiceChat;
    }
}

- (void)stop:(CDVInvokedUrlCommand*)command
{
    NSLog(@"AudioRoute.restoreOriginalAudioSetup(): origAudioCategory=%@, origAudioMode=%@", _audioSession.category, _audioSession.mode);
    [self stopProximitySensor];

    [self audioSessionSetCategory:_origAudioCategory
                          options:0
                       callerMemo:NSStringFromSelector(_cmd)];
    [self audioSessionSetMode:_origAudioMode
                   callerMemo:NSStringFromSelector(_cmd)];
}


@end
