# capacitor-incoming-call-kit

A Capacitor plugin to show incoming call in your Capacitor app(Custom for Android/Callkit for iOS)

This plugin is a modification of the Flutter plugin: flutter_callkit_incoming to suite a capacitor app so all credits goes to hiennguyen92

The plugin is has @capacitor/push-notifications version 6.0.1 integrated

## Install

```bash
npm install capacitor-incoming-call-kit
npx cap sync
```

## API

<docgen-index>

* [`unregisterProximityListener()`](#unregisterproximitylistener)
* [`toggleSpeaker(...)`](#togglespeaker)
* [`isSpeakerOn()`](#isspeakeron)
* [`toggleMicrophone(...)`](#togglemicrophone)
* [`isMicrophoneMuted()`](#ismicrophonemuted)
* [`createAnswer()`](#createanswer)
* [`createOffer(...)`](#createoffer)
* [`setRemoteSdp(...)`](#setremotesdp)
* [`setRemoteIceCandidate(...)`](#setremoteicecandidate)
* [`closePeerConnection()`](#closepeerconnection)
* [`getPeerConnectionStatus()`](#getpeerconnectionstatus)
* [`getRemoteDescriptionStatus()`](#getremotedescriptionstatus)
* [`doMethod(...)`](#domethod)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)
* [Enums](#enums)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### unregisterProximityListener()

```typescript
unregisterProximityListener() => Promise<{ status: string; }>
```

**Returns:** <code>Promise&lt;{ status: string; }&gt;</code>

--------------------


### toggleSpeaker(...)

```typescript
toggleSpeaker({ useSpeaker }: { useSpeaker: boolean; }) => Promise<{ isSpeakerOn: boolean; }>
```

| Param     | Type                                  |
| --------- | ------------------------------------- |
| **`__0`** | <code>{ useSpeaker: boolean; }</code> |

**Returns:** <code>Promise&lt;{ isSpeakerOn: boolean; }&gt;</code>

--------------------


### isSpeakerOn()

```typescript
isSpeakerOn() => Promise<{ isSpeakerOn: boolean; }>
```

**Returns:** <code>Promise&lt;{ isSpeakerOn: boolean; }&gt;</code>

--------------------


### toggleMicrophone(...)

```typescript
toggleMicrophone({ mute }: { mute: boolean; }) => Promise<{ isMicrophoneMuted: boolean; }>
```

| Param     | Type                            |
| --------- | ------------------------------- |
| **`__0`** | <code>{ mute: boolean; }</code> |

**Returns:** <code>Promise&lt;{ isMicrophoneMuted: boolean; }&gt;</code>

--------------------


### isMicrophoneMuted()

```typescript
isMicrophoneMuted() => Promise<{ isMicrophoneMuted: boolean; }>
```

**Returns:** <code>Promise&lt;{ isMicrophoneMuted: boolean; }&gt;</code>

--------------------


### createAnswer()

```typescript
createAnswer() => Promise<SessionDescription>
```

**Returns:** <code>Promise&lt;<a href="#sessiondescription">SessionDescription</a>&gt;</code>

--------------------


### createOffer(...)

```typescript
createOffer({ iceServers, }: { iceServers?: [ { urls: string[]; username: string; credential: string; } ]; }) => Promise<SessionDescription>
```

| Param     | Type                                                                                       |
| --------- | ------------------------------------------------------------------------------------------ |
| **`__0`** | <code>{ iceServers?: [{ urls: string[]; username: string; credential: string; }]; }</code> |

**Returns:** <code>Promise&lt;<a href="#sessiondescription">SessionDescription</a>&gt;</code>

--------------------


### setRemoteSdp(...)

```typescript
setRemoteSdp({ sdp, type, iceServers, }: { sdp: string; type: string; iceServers?: [ { urls: string[]; username: string; credential: string; } ]; }) => Promise<{ status: string; }>
```

| Param     | Type                                                                                                                  |
| --------- | --------------------------------------------------------------------------------------------------------------------- |
| **`__0`** | <code>{ sdp: string; type: string; iceServers?: [{ urls: string[]; username: string; credential: string; }]; }</code> |

**Returns:** <code>Promise&lt;{ status: string; }&gt;</code>

--------------------


### setRemoteIceCandidate(...)

```typescript
setRemoteIceCandidate({ sdpMLineIndex, sdpMid, candidate }: any) => Promise<{ status: string; }>
```

| Param     | Type             |
| --------- | ---------------- |
| **`__0`** | <code>any</code> |

**Returns:** <code>Promise&lt;{ status: string; }&gt;</code>

--------------------


### closePeerConnection()

```typescript
closePeerConnection() => Promise<{ status: string; }>
```

**Returns:** <code>Promise&lt;{ status: string; }&gt;</code>

--------------------


### getPeerConnectionStatus()

```typescript
getPeerConnectionStatus() => Promise<{ status: string; }>
```

**Returns:** <code>Promise&lt;{ status: string; }&gt;</code>

--------------------


### getRemoteDescriptionStatus()

```typescript
getRemoteDescriptionStatus() => Promise<{ status: string; }>
```

**Returns:** <code>Promise&lt;{ status: string; }&gt;</code>

--------------------


### doMethod(...)

```typescript
doMethod(options: { options: string; methodName: MethodNames; parsedOptions: CallKitParams; }) => Promise<Responses>
```

| Param         | Type                                                                                                                                             |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| **`options`** | <code>{ options: string; methodName: <a href="#methodnames">MethodNames</a>; parsedOptions: <a href="#callkitparams">CallKitParams</a>; }</code> |

**Returns:** <code>Promise&lt;<a href="#responses">Responses</a>&gt;</code>

--------------------


### Interfaces


#### SessionDescription

| Prop       | Type                                        |
| ---------- | ------------------------------------------- |
| **`type`** | <code><a href="#sdptype">SdpType</a></code> |
| **`sdp`**  | <code>string</code>                         |


#### CallKitParams

| Prop                                  | Type                                                              |
| ------------------------------------- | ----------------------------------------------------------------- |
| **`id`**                              | <code>string</code>                                               |
| **`nameCaller`**                      | <code>string</code>                                               |
| **`appName`**                         | <code>string</code>                                               |
| **`avatar`**                          | <code>string</code>                                               |
| **`handle`**                          | <code>string</code>                                               |
| **`type`**                            | <code>number</code>                                               |
| **`isOnHold`**                        | <code>boolean</code>                                              |
| **`isMuted`**                         | <code>boolean</code>                                              |
| **`normalHandle`**                    | <code>number</code>                                               |
| **`duration`**                        | <code>number</code>                                               |
| **`textAccept`**                      | <code>string</code>                                               |
| **`textDecline`**                     | <code>string</code>                                               |
| **`textMissedCall`**                  | <code>string</code>                                               |
| **`textCallback`**                    | <code>string</code>                                               |
| **`rationaleMessagePermission`**      | <code>string</code>                                               |
| **`postNotificationMessageRequired`** | <code>string</code>                                               |
| **`missedCallNotification`**          | <code><a href="#notificationparams">NotificationParams</a></code> |
| **`extra`**                           | <code>{ [key: string]: any; }</code>                              |
| **`headers`**                         | <code>{ [key: string]: any; }</code>                              |
| **`android`**                         | <code><a href="#androidparams">AndroidParams</a></code>           |
| **`ios`**                             | <code><a href="#iosparams">IOSParams</a></code>                   |


#### NotificationParams

| Prop                   | Type                 |
| ---------------------- | -------------------- |
| **`id`**               | <code>number</code>  |
| **`showNotification`** | <code>boolean</code> |
| **`subtitle`**         | <code>string</code>  |
| **`callbackText`**     | <code>string</code>  |
| **`isShowCallback`**   | <code>boolean</code> |
| **`int`**              | <code>number</code>  |


#### AndroidParams

| Prop                                      | Type                 |
| ----------------------------------------- | -------------------- |
| **`isCustomNotification`**                | <code>boolean</code> |
| **`isCustomSmallExNotification`**         | <code>boolean</code> |
| **`isShowLogo`**                          | <code>boolean</code> |
| **`isShowCallID`**                        | <code>boolean</code> |
| **`ringtonePath`**                        | <code>string</code>  |
| **`backgroundColor`**                     | <code>string</code>  |
| **`backgroundUrl`**                       | <code>string</code>  |
| **`actionColor`**                         | <code>string</code>  |
| **`textColor`**                           | <code>string</code>  |
| **`incomingCallNotificationChannelName`** | <code>string</code>  |
| **`missedCallNotificationChannelName`**   | <code>string</code>  |
| **`isShowFullLockedScreen`**              | <code>boolean</code> |
| **`isImportant`**                         | <code>boolean</code> |
| **`isBot`**                               | <code>boolean</code> |


#### IOSParams

| Prop                                        | Type                 |
| ------------------------------------------- | -------------------- |
| **`iconName`**                              | <code>string</code>  |
| **`handleType`**                            | <code>string</code>  |
| **`supportsVideo`**                         | <code>boolean</code> |
| **`maximumCallGroups`**                     | <code>number</code>  |
| **`maximumCallsPerCallGroup`**              | <code>number</code>  |
| **`audioSessionMode`**                      | <code>string</code>  |
| **`audioSessionActive`**                    | <code>boolean</code> |
| **`audioSessionPreferredSampleRate`**       | <code>number</code>  |
| **`audioSessionPreferredIOBufferDuration`** | <code>number</code>  |
| **`configureAudioSession`**                 | <code>boolean</code> |
| **`supportsDTMF`**                          | <code>boolean</code> |
| **`supportsHolding`**                       | <code>boolean</code> |
| **`supportsGrouping`**                      | <code>boolean</code> |
| **`supportsUngrouping`**                    | <code>boolean</code> |
| **`ringtonePath`**                          | <code>string</code>  |


### Type Aliases


#### Responses

<code>void | { isMuted: boolean } | { calls: CallKitParams[] } | { isVersionOk: boolean } | { devicePushTokenVoIP: string }</code>


#### MethodNames

<code>'showCallkitIncoming' | 'checkIsVersionOk' | 'sendPendingAcceptEvent' | 'showCallkitIncomingSilently' | 'showMissCallNotification' | 'startCall' | 'muteCall' | 'holdCall' | 'isMuted' | 'endCall' | 'callConnected' | 'endAllCalls' | 'activeCalls' | 'getDevicePushTokenVoIP' | 'silenceEvents' | 'requestNotificationPermission' | 'requestFullIntentPermission' | 'hideCallkitIncoming' | 'endNativeSubsystemOnly' | 'setAudioRoute'</code>


### Enums


#### SdpType

| Members        | Value                   |
| -------------- | ----------------------- |
| **`offer`**    | <code>'offer'</code>    |
| **`prAnswer`** | <code>'prAnswer'</code> |
| **`answer`**   | <code>'answer'</code>   |
| **`rollback`** | <code>'rollback'</code> |

</docgen-api>
