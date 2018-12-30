
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

var audioRoute = new AudioRoute();
module.exports = audioRoute;
