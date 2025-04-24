'use strict';

var core = require('@capacitor/core');

/// <reference types="@capacitor/cli" />
exports.SdpType = void 0;
(function (SdpType) {
    SdpType["offer"] = "offer";
    SdpType["prAnswer"] = "prAnswer";
    SdpType["answer"] = "answer";
    SdpType["rollback"] = "rollback";
})(exports.SdpType || (exports.SdpType = {}));

const FlutterCallkitIncoming = core.registerPlugin('FlutterCallkitIncoming', {
    web: () => Promise.resolve().then(function () { return web; }).then((m) => new m.FlutterCallkitIncomingWeb()),
});

class FlutterCallkitIncomingWeb extends core.WebPlugin {
}

var web = /*#__PURE__*/Object.freeze({
    __proto__: null,
    FlutterCallkitIncomingWeb: FlutterCallkitIncomingWeb
});

exports.FlutterCallkitIncoming = FlutterCallkitIncoming;
//# sourceMappingURL=plugin.cjs.js.map
