
function AudioRoute() {
    cordova.exec(routeChangeCallback, null, 'AudioRoute', 'setRouteChangeCallback', []);
}

AudioRoute.prototype.currentOutputs = function(successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, 'AudioRoute', 'currentOutputs', []);
};

AudioRoute.prototype.overrideOutput = function(output, successCallback, errorCallback) {
    if (output !== 'default' && output !== 'speaker') {
        throw new Error('output must be one of "default" or "speaker"');
    }
    cordova.exec(successCallback, errorCallback, 'AudioRoute', 'overrideOutput', [output]);
};

AudioRoute.prototype.startProximitySensor = function(successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, 'AudioRoute', 'startProximitySensor', []);
};

AudioRoute.prototype.setForceSpeakerphoneOn = function(flag, successCallback, errorCallback) {
    if (isInt(flag) && (flag === -1 || flag === 0 || flag ===1)) {
        flag = flag;
    } else {
        flag = flag ? 1 : -1;
    }
    cordova.exec(successCallback, errorCallback, 'AudioRoute', 'setForceSpeakerphoneOn', [flag]);
};

AudioRoute.prototype.start = function(type, successCallback, errorCallback) {
    if ((type === null) || (type !== null && (type !== 'audio' || type !== 'video'))) {
        type = 'audio';
    }
    cordova.exec(successCallback, errorCallback, 'AudioRoute', 'start', [type]);
};

AudioRoute.prototype.stop = function(successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, 'AudioRoute', 'stop', []);
};

function routeChangeCallback(reason) {
    cordova.fireDocumentEvent('audioroute-changed', {reason: reason});
}

function isInt(value) {
    var x;
    return isNaN(value) ? !1 : (x = parseFloat(value), (0 | x) === x);
}

var audioRoute = new AudioRoute();
module.exports = audioRoute;
