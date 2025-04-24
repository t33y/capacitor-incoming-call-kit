import { registerPlugin } from '@capacitor/core';
const FlutterCallkitIncoming = registerPlugin('FlutterCallkitIncoming', {
    web: () => import('./web').then((m) => new m.FlutterCallkitIncomingWeb()),
});
export * from './definitions';
export { FlutterCallkitIncoming };
//# sourceMappingURL=index.js.map