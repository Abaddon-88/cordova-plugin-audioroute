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

AVAudioSession *_session;

NSString *_incallAudioMode;
NSString *_incallAudioCategory;
NSString *_origAudioCategory;
NSString *_origAudioMode;

NSString *_media;

NSUInteger _optionsFlag;
NSUInteger _originalOptionsFlag;

- (void)pluginInitialize 
{
    NSLog(@"Initializing AudioRoute plugin");
    callbackId = nil;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                          selector:@selector(routeChange:)
                                          name:AVAudioSessionRouteChangeNotification
                                          object:nil];

    _incallAudioMode = AVAudioSessionModeVoiceChat;
    _incallAudioCategory = AVAudioSessionCategoryPlayAndRecord;
    _origAudioCategory = nil;
    _origAudioMode = nil;

    _optionsFlag =  AVAudioSessionCategoryOptionDefaultToSpeaker    |
                    AVAudioSessionCategoryOptionAllowBluetooth      |
                    AVAudioSessionCategoryOptionAllowAirPlay        |
                    AVAudioSessionCategoryOptionAllowBluetoothA2DP;

    _media = @"audio";

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

    _session = [AVAudioSession sharedInstance];

    // make sure the AVAudioSession is properly configured
    [_session setActive: YES error: nil];
    [_session setCategory:AVAudioSessionCategoryPlayAndRecord mode:_incallAudioMode options:_optionsFlag error:nil];

    if (output != nil) {
        if ([output isEqualToString:@"speaker"]) {
            success = [_session overrideOutputAudioPort:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
        } else {
            success = [_session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
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

- (void)setAudioMode:(CDVInvokedUrlCommand *)command
{
    NSError* __autoreleasing err = nil;
    NSString* mode = [command.arguments objectAtIndex:0];
    
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_None;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    if ([mode isEqualToString:@"earpiece"]) {
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
        audioRouteOverride = kAudioSessionProperty_OverrideCategoryDefaultToSpeaker;
        AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
    } else if ([mode isEqualToString:@"speaker"] || [mode isEqualToString:@"ringtone"]) {
        [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&err];
    } else if ([mode isEqualToString:@"normal"]) {
        [session setCategory:AVAudioSessionCategorySoloAmbient error:&err];
    }
}

- (void)start:(CDVInvokedUrlCommand*)command
{
    NSString* mediaType = [command.arguments objectAtIndex:0];
    
    _session = [AVAudioSession sharedInstance];

    _origAudioCategory = _session.category;
    _origAudioMode = _session.mode;
    _originalOptionsFlag = _session.categoryOptions;

    _media = mediaType;

    NSString *targetMode = @"";
    if ([_media isEqualToString:@"video"]) {
        targetMode = AVAudioSessionModeVideoChat;
    } else {
        targetMode = AVAudioSessionModeVoiceChat;
    }

    _incallAudioMode = targetMode;
    if (targetMode.length > 0 && ![_session.mode isEqualToString:targetMode]) {
        [_session setActive: YES error: nil];
        [_session setCategory:AVAudioSessionCategoryPlayAndRecord mode:targetMode options:_optionsFlag  error:nil];
    }
}

- (void)stop:(CDVInvokedUrlCommand*)command
{
    if(_session) {
        [_session setCategory:_origAudioCategory mode:_origAudioMode options:_originalOptionsFlag error:nil];
        [_session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    }
}


@end
