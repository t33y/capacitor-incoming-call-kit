import UIKit
import CallKit
import Capacitor
import AVFoundation
import WebRTC
import Intents

import Foundation
import UserNotifications

enum PushNotificationError: Error {
    case tokenParsingFailed
    case tokenRegistrationFailed
}

enum PushNotificationsPermissions: String {
    case prompt
    case denied
    case granted
}

@available(iOS 10.0, *)
@objc(SwiftFlutterCallkitIncomingPlugin)
public class SwiftFlutterCallkitIncomingPlugin: CAPPlugin, CAPBridgedPlugin, CXProviderDelegate, WebRTCClientDelegate {
    public let identifier = "SwiftFlutterCallkitIncomingPlugin"
    public let jsName = "FlutterCallkitIncoming"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name:"createPeer", returnType: CAPPluginReturnPromise ),
        CAPPluginMethod(name:"getRemoteDescriptionStatus", returnType: CAPPluginReturnPromise ),
        CAPPluginMethod(name:"toggleSpeaker", returnType: CAPPluginReturnPromise ),
        CAPPluginMethod(name:"isSpeakerOn", returnType: CAPPluginReturnPromise ),
        CAPPluginMethod(name:"toggleMicrophone", returnType: CAPPluginReturnPromise ),
        CAPPluginMethod(name:"isMicrophoneMuted", returnType: CAPPluginReturnPromise ),
        CAPPluginMethod(name:"setRemoteSdp", returnType: CAPPluginReturnPromise ),
        CAPPluginMethod(name:"setRemoteIceCandidate", returnType: CAPPluginReturnPromise ),
        CAPPluginMethod(name: "createAnswer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "createOffer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "closePeerConnection", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getPeerConnectionStatus", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "doMethod", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "register", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "unregister", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "checkPermissions", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "requestPermissions", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getDeliveredNotifications", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "removeAllDeliveredNotifications", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "removeDeliveredNotifications", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "createChannel", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "listChannels", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "deleteChannel", returnType: CAPPluginReturnPromise)
    ]
    private let notificationDelegateHandler = PushNotificationsHandler()
    private var appDelegateRegistrationCalled: Bool = false
    
    static let ACTION_DID_UPDATE_DEVICE_PUSH_TOKEN_VOIP = "com.hiennv.flutter_callkit_incoming.DID_UPDATE_DEVICE_PUSH_TOKEN_VOIP"
    
    static let ACTION_CALL_INCOMING = "com.hiennv.flutter_callkit_incoming.ACTION_CALL_INCOMING"
    public static let ACTION_CALL_START = "com.hiennv.flutter_callkit_incoming.ACTION_CALL_START"
    public static let ACTION_CALL_ACCEPT = "com.hiennv.flutter_callkit_incoming.ACTION_CALL_ACCEPT"
    static let ACTION_CALL_DECLINE = "com.hiennv.flutter_callkit_incoming.ACTION_CALL_DECLINE"
    static let ACTION_CALL_ENDED = "com.hiennv.flutter_callkit_incoming.ACTION_CALL_ENDED"
    public static let ACTION_CALL_TIMEOUT = "com.hiennv.flutter_callkit_incoming.ACTION_CALL_TIMEOUT"
    static let ACTION_CALL_CUSTOM = "com.hiennv.flutter_callkit_incoming.ACTION_CALL_CUSTOM"
    
    static let ACTION_CALL_TOGGLE_HOLD = "com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_HOLD"
    static let ACTION_CALL_TOGGLE_MUTE = "com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_MUTE"
    static let ACTION_CALL_TOGGLE_DMTF = "com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_DMTF"
    static let ACTION_CALL_TOGGLE_GROUP = "com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_GROUP"
    static let ACTION_CALL_TOGGLE_AUDIO_SESSION = "com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_AUDIO_SESSION"
    
    @objc public private(set) static var sharedInstance: SwiftFlutterCallkitIncomingPlugin!
    
    private var callManager: CallManager
    private var webRTCManager: NativeWebrtcManager?
    private var sharedProvider: CXProvider? = nil
    
    private var outgoingCall : Call?
    private var answerCall : Call?
    
    private var data: CallData?
    private var isFromPushKit: Bool = false
    private var silenceEvents: Bool = false
    private var lastEndCallEvent: [String : Any]?
    private var lastAcceptCallEvent: [String : Any]?
    private var lastIncomingCallEvent: [String : Any]?
    private let devicePushTokenVoIP = "DevicePushTokenVoIP"
    private func postRequest(_ url: String, _ json: String?) {
        // if (self.bridge == nil) {
            Task {
                do {
    //                NSLog("postRequest with url: \(String(describing: url)) and json: \(String(describing: json))")
                    var request = URLRequest(url: URL(string: url)!)
                    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

                    // Use the async variant of URLSession to make an HTTP POST request:
                    request.httpMethod = "POST"
                    let (_, _) = try await URLSession.shared.upload(for: request, from: json?.data(using: .utf8) ?? Foundation.Data())
    //                NSLog("postRequest successful with response: \(String(describing: response)) and data: \(String(decoding: data, as: UTF8.self))")
                } catch {
                    NSLog("postRequest attempt with error \(String(describing: error))")
                }
            }
        // } else {
        //     NSLog("postRequest ignored for \(String(describing: url)) as app is active")
        // }
    }


    
    func webRTCClient(_ client: NativeWebrtcManager, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        DispatchQueue.main.async {
            self.notifyListeners("onIceCandidate", data: ["iceCandidate":["candidate": candidate.sdp,
                                                                        "sdpMLineIndex":candidate.sdpMLineIndex,
                                                                          "sdpMid": candidate.sdpMid ?? ""]])
        }

    }
    
    func webRTCClient(_ client: NativeWebrtcManager, didChangeConnectionState state: RTCIceConnectionState) {

        DispatchQueue.main.async {
            self.notifyListeners("onConnectionStateChange", data:["connectionState": state.description])
//            if state == .connected{
//                guard let data = self.getAcceptedCall() else{
//                    return print("Can not connect call. invalid call data")
//                }
//                print("Call connected calling connectedCall")
//                self.connectedCall(data)
//            }
            
            if state == .failed || state == .disconnected{
                self.webRTCManager?.close()
                        }
            
        }
           

    }
    
    func webRTCClient(_ client: NativeWebrtcManager, didReceiveData data: Data) {
        let base64String = data.base64EncodedString()
        DispatchQueue.main.async {
            self.notifyListeners("onDataReceived", data: ["dataReceived": base64String])
        }
        
    }
    

    
    public func sendEvent(_ event: String, _ body: [String : Any]?) {
        if silenceEvents {
            print(event, " silenced")
            return
        } else {
            if (self.bridge != nil) {
                self.notifyListeners(event, data: body ?? [:])
            } 
           else {
               if (event == SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_ACCEPT) {
                   lastAcceptCallEvent = body
               } else if (event == SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_INCOMING) {
                   lastIncomingCallEvent = body
               } else if (event == SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_ENDED) {
                   lastEndCallEvent = body
               }
           }
        }
        
    }
    
    @objc public func sendEventCustom(_ event: String, body: [String : Any]?) {
        self.notifyListeners(event, data: body ?? [:])
    }
    
    public static func sharePluginWithRegister(with pluginInstance: SwiftFlutterCallkitIncomingPlugin) {
        if(sharedInstance == nil){
            sharedInstance = pluginInstance
        }
    }
    
    override public func load() {
        SwiftFlutterCallkitIncomingPlugin.sharePluginWithRegister(with: self)

        self.bridge?.notificationRouter.pushNotificationHandler = self.notificationDelegateHandler
        self.notificationDelegateHandler.plugin = self

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didRegisterForRemoteNotificationsWithDeviceToken(notification:)),
                                               name: .capacitorDidRegisterForRemoteNotifications,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didFailToRegisterForRemoteNotificationsWithError(notification:)),
                                               name: .capacitorDidFailToRegisterForRemoteNotifications,
                                               object: nil)
        
//        self.webRTCManager = NativeWebrtcManager(iceServers:["stun:stun.l.google.com:19302",
//                                  "stun:stun1.l.google.com:19302",
//                                  "stun:stun2.l.google.com:19302",
//                                  "stun:stun3.l.google.com:19302",
//                                  "stun:stun4.l.google.com:19302"]) // Create only when needed
//        
//        self.webRTCManager?.delegate = self
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(handleVideoCallRequest(_:)), name: .videoCallRequested, object: nil)
        
        if self.webRTCManager == nil {
    let server =        RTCIceServer(
                urlStrings: ["stun:stun.l.google.com:19302",
                             "stun:stun1.l.google.com:19302",
                             "stun:stun2.l.google.com:19302",
                             "stun:stun3.l.google.com:19302",
                             "stun:stun4.l.google.com:19302"]
    
            )
            self.webRTCManager = NativeWebrtcManager(iceServers:[server]) // Create only when needed
            self.webRTCManager?.delegate = self
            print("✅ WebRTCManager initialized in init")
        }
    }
    
    
    public override init() {
        callManager = CallManager()
        super.init()
                if self.webRTCManager == nil {
            let server =        RTCIceServer(
                        urlStrings: ["stun:stun.l.google.com:19302",
                                     "stun:stun1.l.google.com:19302",
                                     "stun:stun2.l.google.com:19302",
                                     "stun:stun3.l.google.com:19302",
                                     "stun:stun4.l.google.com:19302"]
            
                    )
                    self.webRTCManager = NativeWebrtcManager(iceServers:[server]) // Create only when needed
                    self.webRTCManager?.delegate = self
                    print("✅ WebRTCManager initialized in init")
                }
        
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

        @objc func toggleSpeaker(_ call: CAPPluginCall) {
        let useSpeaker = call.getBool("useSpeaker") ?? false
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
//            try audioSession.setCategory(.playAndRecord, options: useSpeaker ? .defaultToSpeaker : [])
            try audioSession.overrideOutputAudioPort(useSpeaker ? .speaker : .none)
            try audioSession.setActive(true)
            call.resolve(["isSpeakerOn": useSpeaker])
        } catch {
            call.reject("Unable to toggle speaker", error.localizedDescription)
        }
    }

    @objc func isSpeakerOn(_ call: CAPPluginCall) {
        let audioSession = AVAudioSession.sharedInstance()
        let isSpeakerOn = audioSession.currentRoute.outputs.contains { $0.portType == .builtInSpeaker }
        call.resolve(["isSpeakerOn": isSpeakerOn])
    }

        @objc func toggleMicrophone(_ call: CAPPluginCall) {
        // Get the "mute" parameter from the call
        let mute = call.getBool("mute", false)

        // Get the shared audio session
        let audioSession = AVAudioSession.sharedInstance()

        do {
            // Set the microphone mute state
            try audioSession.setActive(!mute)
            if mute {
                try audioSession.overrideOutputAudioPort(.none)
            } else {
                try audioSession.overrideOutputAudioPort(.speaker)
            }

            // Return the current microphone status
            let isMuted = !audioSession.isInputAvailable
            let ret = [
                "isMicrophoneMuted": isMuted
            ]
            call.resolve(ret)
        } catch {
            // Handle errors
            call.reject("Failed to toggle microphone: \(error.localizedDescription)")
        }
    }

    @objc func isMicrophoneMuted(_ call: CAPPluginCall) {
        // Get the shared audio session
        let audioSession = AVAudioSession.sharedInstance()

        // Check if the microphone is muted
        let isMuted = !audioSession.isInputAvailable

        // Return the status
        let ret = [
            "isMicrophoneMuted": isMuted
        ]
        call.resolve(ret)
    }
    

    
    @objc func handleVideoCallRequest(_ notification: Notification) {
        print("requesting video call")
        guard let userInfo = notification.userInfo,
              let contact = userInfo["contact"] as? String else { return }

        // Notify JavaScript
        self.notifyListeners("videoIntenthandle", data: ["contact": contact])

    }

    /**
     * Register for push notifications
     */
    @objc func register(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
        call.resolve()
    }

    /**
     * Unregister for remote notifications
     */
    @objc func unregister(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            UIApplication.shared.unregisterForRemoteNotifications()
            call.resolve()
        }
    }

        // MARK: - WebRTC
//    @objc func closePeerConnection(_ call: CAPPluginCall) {
//        ensureWebRTCManager()
//    guard let webRTCManager = self.webRTCManager else {
//        call.reject("WebRTC manager or peer connection is not initialized")
//        return
//    }
//
//
//        webRTCManager.peerConnection.close()
//
//
//    call.resolve(["status": "closed"])
//        
//    }
    @objc func createPeer(_ call: CAPPluginCall) {
        
        if let createNew = call.options["iceServers"]as? [[String: Any]] {
            let iceServersConfig = createNew.compactMap { server -> RTCIceServer? in
                guard let urls = server["urls"] as? [String] else { return nil }
                return RTCIceServer(
                    urlStrings: urls,
                    username: server["username"] as? String,
                    credential: server["credential"] as? String
                )
            }
            self.webRTCManager?.close()
            self.webRTCManager = NativeWebrtcManager(iceServers:iceServersConfig) // Create only when needed
            self.webRTCManager?.delegate = self
            print("✅ WebRTCManager initialization requested")
        }
        
            guard let webRTCManager = self.webRTCManager else {
        call.reject("WebRTC manager not initialized")
        return
    }

                call.resolve(["status": "peer created"])
            
        
    }
    
    
    @objc func createOffer(_ call: CAPPluginCall) {
        
        if let createNew = call.options["iceServers"]as? [[String: Any]] {
            let iceServersConfig = createNew.compactMap { server -> RTCIceServer? in
                guard let urls = server["urls"] as? [String] else { return nil }
                return RTCIceServer(
                    urlStrings: urls,
                    username: server["username"] as? String,
                    credential: server["credential"] as? String
                )
            }
            self.webRTCManager?.close()
            self.webRTCManager = NativeWebrtcManager(iceServers:iceServersConfig) // Create only when needed
            self.webRTCManager?.delegate = self
            print("✅ WebRTCManager initialization requested")
        }
        
            guard let webRTCManager = self.webRTCManager else {
        call.reject("WebRTC manager not initialized")
        return
    }
        webRTCManager.offer{(sdp) in
            let sessionDescription = SessionDescription(from: sdp)
                 
                 let sessionDescriptionDict: [String: Any] = [
                     "sdp": sessionDescription.sdp,
                     "type": sessionDescription.type.rawValue
                 ]
                call.resolve(sessionDescriptionDict)
            }
        
    }
    
    @objc func createAnswer(_ call: CAPPluginCall) {
//        ensureWebRTCManager()
            guard let webRTCManager = self.webRTCManager else {
        call.reject("WebRTC manager not initialized")
        return
    }
        webRTCManager.answer{(sdp) in

            let sessionDescription = SessionDescription(from: sdp)
                 
                 let sessionDescriptionDict: [String: Any] = [
                    "sdp": sessionDescription.sdp,
                     "type": sessionDescription.type.rawValue
                 ]
                call.resolve(sessionDescriptionDict)
            }
        
    }
    
    @objc func setRemoteIceCandidate(_ call: CAPPluginCall) {
        guard let sdpMid = call.getString("sdpMid"),
              let sdpMLineIndex = call.getInt("sdpMLineIndex"),
              let candidate = call.getString("candidate") else {
            call.reject("Missing ICE candidate parameters")
            return
        }

        let rtcCandidate = RTCIceCandidate(
            sdp: candidate,
            sdpMLineIndex: Int32(sdpMLineIndex),
            sdpMid: sdpMid
        )
        
        if self.webRTCManager == nil {
            call.resolve(["status": "no peerConnection"])
        }

        
        self.webRTCManager?.set(remoteCandidate: rtcCandidate){error in
            if let error = error {
                call.reject("Failed to add ICE Candidate: \(error.localizedDescription)")
            } else {
                print("ice candidate added successfully")
                call.resolve(["status": "ICE Candidate added"])
            }
            }
        
    }
    
    @objc func setRemoteSdp(_ call: CAPPluginCall) {
        guard let sdp = call.getString("sdp"),
              let sdpTypeString = call.getString("type"),
              let sdpType = SdpType(from: sdpTypeString) else {
            call.reject("Invalid parameters")
            return
        }
        if let createNew = call.options["iceServers"]as? [[String: Any]] {
            let iceServersConfig = createNew.compactMap { server -> RTCIceServer? in
                guard let urls = server["urls"] as? [String] else { return nil }
                return RTCIceServer(
                    urlStrings: urls,
                    username: server["username"] as? String,
                    credential: server["credential"] as? String
                )
            }
            self.webRTCManager?.close()
            self.webRTCManager = NativeWebrtcManager(iceServers:iceServersConfig) // Create only when needed
            self.webRTCManager?.delegate = self
            print("✅ WebRTCManager initialization requested")
        }
        
        let rtcSdpType = sdpType.rtcSdpType
        
        let rtcSessionDescription = RTCSessionDescription(type: rtcSdpType, sdp: sdp )
        self.webRTCManager?.set(remoteSdp: rtcSessionDescription){error in
            if let error = error {
                call.reject("Failed to add sdp: \(error.localizedDescription)")
            } else {
                print("sdp set successfully")
                call.resolve(["status": "Sdp added"])
            }
        }
        
    }
    
    @objc func getRemoteDescriptionStatus(_ call: CAPPluginCall) {
        let status = self.webRTCManager?.remoteDescriptionStatus()
        call.resolve(["status": status ?? "unavailable"])
    }

        
    @objc func getPeerConnectionStatus(_ call: CAPPluginCall) {
        let status = self.webRTCManager != nil ? "active" : "not initialized"
        call.resolve(["status": status])
    }

    
    // MARK: - Request notification permission
    @objc override public func requestPermissions(_ call: CAPPluginCall) {
        self.notificationDelegateHandler.requestPermissions { granted, error in
            guard error == nil else {
                if let err = error {
                    call.reject(err.localizedDescription)
                    return
                }

                call.reject("unknown error in permissions request")
                return
            }

            var result: PushNotificationsPermissions = .denied

            if granted {
                result = .granted
            }

            call.resolve(["receive": result.rawValue])
        }
    }

    /**
     * Check notification permission
     */
    @objc override public func checkPermissions(_ call: CAPPluginCall) {
        self.notificationDelegateHandler.checkPermissions { status in
            var result: PushNotificationsPermissions = .prompt

            switch status {
            case .notDetermined:
                result = .prompt
            case .denied:
                result = .denied
            case .ephemeral, .authorized, .provisional:
                result = .granted
            @unknown default:
                result = .prompt
            }

            call.resolve(["receive": result.rawValue])
        }
    }

    /**
     * Get notifications in Notification Center
     */
    @objc func getDeliveredNotifications(_ call: CAPPluginCall) {
        if !appDelegateRegistrationCalled {
            call.reject("event capacitorDidRegisterForRemoteNotifications not called.  Visit https://capacitorjs.com/docs/apis/push-notifications for more information")
            return
        }
        UNUserNotificationCenter.current().getDeliveredNotifications(completionHandler: { (notifications) in
            let ret = notifications.map({ (notification) -> [String: Any] in
                return self.notificationDelegateHandler.makeNotificationRequestJSObject(notification.request)
            })
            call.resolve([
                "notifications": ret
            ])
        })
    }

    /**
     * Remove specified notifications from Notification Center
     */
    @objc func removeDeliveredNotifications(_ call: CAPPluginCall) {
        if !appDelegateRegistrationCalled {
            call.reject("event capacitorDidRegisterForRemoteNotifications not called.  Visit https://capacitorjs.com/docs/apis/push-notifications for more information")
            return
        }
        guard let notifications = call.getArray("notifications", JSObject.self) else {
            call.reject("Must supply notifications to remove")
            return
        }

        let ids = notifications.map { $0["id"] as? String ?? "" }
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
        call.resolve()
    }

    /**
     * Remove all notifications from Notification Center
     */
    @objc func removeAllDeliveredNotifications(_ call: CAPPluginCall) {
        if !appDelegateRegistrationCalled {
            call.reject("event capacitorDidRegisterForRemoteNotifications not called.  Visit https://capacitorjs.com/docs/apis/push-notifications for more information")
            return
        }
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        DispatchQueue.main.async(execute: {
            UIApplication.shared.applicationIconBadgeNumber = 0
        })
        call.resolve()
    }

    @objc func createChannel(_ call: CAPPluginCall) {
        call.unimplemented("Not available on iOS")
    }

    @objc func deleteChannel(_ call: CAPPluginCall) {
        call.unimplemented("Not available on iOS")
    }

    @objc func listChannels(_ call: CAPPluginCall) {
        call.unimplemented("Not available on iOS")
    }

    @objc public func didRegisterForRemoteNotificationsWithDeviceToken(notification: NSNotification) {
        appDelegateRegistrationCalled = true
        if let deviceToken = notification.object as? Foundation.Data {
            let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
            notifyListeners("registration", data: [
                "value": deviceTokenString
            ])
        } else if let stringToken = notification.object as? String {
            notifyListeners("registration", data: [
                "value": stringToken
            ])
        } else {
            notifyListeners("registrationError", data: [
                "error": PushNotificationError.tokenParsingFailed.localizedDescription
            ])
        }
    }
    
    

    @objc public func didFailToRegisterForRemoteNotificationsWithError(notification: NSNotification) {
        appDelegateRegistrationCalled = true
        guard let error = notification.object as? Error else {
            return
        }
        notifyListeners("registrationError", data: [
            "error": error.localizedDescription
        ])
    }
    
    // MARK: - Callkit Implementation
    
    @objc public func doMethod(_ pluginCall: CAPPluginCall) {
        let name = pluginCall.getString("methodName") ?? ""
        let options = pluginCall.getObject("parsedOptions")
        switch name {
        case "checkIsVersionOk":
            checkIsVersionOk(pluginCall)
            break
        case "sendPendingAcceptEvent":
            sendPendingAcceptEvent()
            if lastAcceptCallEvent != nil{
                pluginCall.resolve(lastAcceptCallEvent ?? [:])
                return
            }
            pluginCall.resolve()
            
            break
        case "showCallkitIncoming":
            guard let getArgs = options else {
                pluginCall.resolve()
                return
            }
            self.data = CallData(args: getArgs)
            showCallkitIncoming(self.data!, fromPushKit: false)
            pluginCall.resolve()
            break
        case "showMissCallNotification":
            pluginCall.resolve()
            break
        case "startCall":
//            guard let args = options else {
//                pluginCall.resolve()
//                return
//            }
            if let getArgs = options {
                self.data = CallData(args: getArgs)
                self.startCall(self.data!, fromPushKit: false)
                // self.createOffer(pluginCall)
            }
            break
        case "endCall":
            guard let args = options else {
                pluginCall.resolve()
                return
            }
            if(self.isFromPushKit){
                self.endCall(self.data!)
            }else{
                if let getArgs = options {
                    self.data = CallData(args: getArgs)
                    self.endCall(self.data!)
                }
            }
            pluginCall.resolve()
            break
        case "muteCall":
            guard let args = options,
                  let callId = args["id"] as? String,
                  let isMuted = args["isMuted"] as? Bool else {
                pluginCall.resolve()
                return
            }
            
            self.muteCall(callId, isMuted: isMuted)
            pluginCall.resolve()
            break
        case "isMuted":
            guard let args = options,
                  let callId = args["id"] as? String else{
                pluginCall.resolve(["isMuted": false])
                return
            }
            guard let callUUID = UUID(uuidString: callId),
                  let call = self.callManager.callWithUUID(uuid: callUUID) else {
                pluginCall.resolve(["isMuted": false])
                return
            }
            pluginCall.resolve(["isMuted": call.isMuted])
            break
        case "holdCall":
            guard let args = options as? [String: Any] ,
                  let callId = args["id"] as? String,
                  let onHold = args["isOnHold"] as? Bool else {
                pluginCall.resolve()
                return
            }
            self.holdCall(callId, onHold: onHold)
            pluginCall.resolve()
            break
        case "callConnected":
            guard let args = options else {
                pluginCall.resolve()
                return
            }
            if(self.isFromPushKit){
                self.connectedCall(self.data!)
            }else{
                if let getArgs = options {
                    self.data = CallData(args: args)
                    self.connectedCall(self.data!)
                }
            }
            pluginCall.resolve()
            break
        case "activeCalls":
            pluginCall.resolve(["calls": self.callManager.activeCalls()])
            break;
        case "endAllCalls":
            self.callManager.endCallAlls()
            pluginCall.resolve()
            break
        case "getDevicePushTokenVoIP":
            pluginCall.resolve(["devicePushTokenVoIP": self.getDevicePushTokenVoIP()])
            break;
        case "silenceEvents":
            guard let silence = options as? Bool else {
                pluginCall.resolve()
                return
            }
            
            self.silenceEvents = silence
            pluginCall.resolve()
            break;
        case "requestNotificationPermission":
            pluginCall.resolve()
            break
         case "requestFullIntentPermission":
            pluginCall.resolve()
            break
        case "hideCallkitIncoming":
            pluginCall.resolve()
            break
        case "endNativeSubsystemOnly":
            pluginCall.resolve()
            break
        case "setAudioRoute":
            pluginCall.resolve()
            break
        default:
            pluginCall.resolve()
        }
    }
    
    @objc public func setDevicePushTokenVoIP(_ deviceToken: String) {
        UserDefaults.standard.set(deviceToken, forKey: devicePushTokenVoIP)
        self.sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_DID_UPDATE_DEVICE_PUSH_TOKEN_VOIP, ["deviceTokenVoIP":deviceToken])
    }
    
    @objc public func getDevicePushTokenVoIP() -> String {
        return UserDefaults.standard.string(forKey: devicePushTokenVoIP) ?? ""
    }
    
    @objc public func getAcceptedCall() -> CallData? {
        NSLog("Call data ids \(String(describing: data?.uuid)) \(String(describing: answerCall?.uuid.uuidString))")
        if data?.uuid.lowercased() == answerCall?.uuid.uuidString.lowercased() {
            return data
        }
        return nil
    }
    
    @objc public func checkIsVersionOk(_ pluginCall: CAPPluginCall) {
        var body = [ "isVersionOk": false ]
        if #available(iOS 14.0, *) {
            body["isVersionOk"] = true
        }
        pluginCall.resolve(body)
    }
    
    @objc public func sendPendingAcceptEvent() {
        if (lastIncomingCallEvent != nil) {
            sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_INCOMING, lastIncomingCallEvent)
            lastIncomingCallEvent = nil
        }
        if (lastAcceptCallEvent != nil) {
            sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_ACCEPT, lastAcceptCallEvent)
            lastAcceptCallEvent = nil
        }
        if (lastEndCallEvent != nil) {
            sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_ENDED, lastEndCallEvent)
            lastEndCallEvent = nil
        }
    }
    
    @objc public func showCallkitIncoming(_ data: CallData, fromPushKit: Bool) {
        self.isFromPushKit = fromPushKit
        if(fromPushKit){
            self.data = data
        }
        
        var handle: CXHandle?
        handle = CXHandle(type: self.getHandleType(data.handleType), value: data.getEncryptHandle())
        
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = handle
        callUpdate.supportsDTMF = data.supportsDTMF
        callUpdate.supportsHolding = data.supportsHolding
        callUpdate.supportsGrouping = data.supportsGrouping
        callUpdate.supportsUngrouping = data.supportsUngrouping
        callUpdate.hasVideo = data.type > 0 ? true : false
        callUpdate.localizedCallerName = data.nameCaller
        
        initCallkitProvider(data)
        
        let uuid = UUID(uuidString: data.uuid)
        
        configurAudioSession()
        self.sharedProvider?.reportNewIncomingCall(with: uuid!, update: callUpdate) { error in
            if(error == nil) {
                self.configurAudioSession()
                let call = Call(uuid: uuid!, data: data)
                call.handle = data.handle
                self.callManager.addCall(call)
                self.sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_INCOMING, data.toJSON())
                self.endCallNotExist(data)
            }
        }

    }
    
    @objc public func startCall(_ data: CallData, fromPushKit: Bool) {
        self.isFromPushKit = fromPushKit
        if(fromPushKit){
            self.data = data
        }
        initCallkitProvider(data)
        self.callManager.startCall(data)
        
    }
    
//    @objc func addRemoveVideo(_ call: CAPPluginCall) {
//        guard let isVideo = call.getBool("isVideo"),
//              let id = call.getString("id") else {
//            call.reject("Missing ICE candidate parameters")
//            return
//        }
//        let uuid = UUID(uuidString: id)
//        let callUpdate = CXCallUpdate()
//        callUpdate.hasVideo = isVideo
//        DispatchQueue.main.async {
//            reportCall(
//                with: uuid,
//                updated:callUpdate
//            ){error in
//                if let error = error {
//                    call.reject("Failed to update video: \(error.localizedDescription)")
//                } else {
//                    call.resolve(["status": isVideo? "Video added":"Video removed"])
//                }
//            }
//        }
//
//
//        
//    }
    
    @objc public func muteCall(_ callId: String, isMuted: Bool) {
        guard let callId = UUID(uuidString: callId),
              let call = self.callManager.callWithUUID(uuid: callId) else {
            return
        }
        if call.isMuted == isMuted {
            self.sendMuteEvent(callId.uuidString, isMuted)
        } else {
            self.callManager.muteCall(call: call, isMuted: isMuted)
        }
    }
    
    @objc public func holdCall(_ callId: String, onHold: Bool) {
        if let appDelegate = UIApplication.shared.delegate as? CallkitIncomingAppDelegate {
            appDelegate.onHoldCall(callId, onHold)
        }
    }
    
    @objc public func endCall(_ data: CallData) {
         var call: Call? = nil
        if(self.isFromPushKit){
            call = Call(uuid: UUID(uuidString: self.data!.uuid)!, data: data)
            self.isFromPushKit = false
            self.sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_ENDED, data.toJSON())
        }else {
            call = Call(uuid: UUID(uuidString: data.uuid)!, data: data)
        }
            guard let validCall = call else {
        return
    }
        DispatchQueue.main.async {
            self.callManager.endCall(call: validCall)
            self.webRTCManager?.close()
        }
    }
    
    @objc public func connectedCall(_ data: CallData) {
        var call: Call? = nil
        if(self.isFromPushKit){
            call = Call(uuid: UUID(uuidString: self.data!.uuid)!, data: data)
            self.isFromPushKit = false
        }else {
            call = Call(uuid: UUID(uuidString: data.uuid)!, data: data)
        }
        self.callManager.connectedCall(call: call!)

    }
    
    @objc public func activeCalls() -> [[String: Any]] {
        return self.callManager.activeCalls()
    }
    
    @objc public func endAllCalls() {
        self.isFromPushKit = false
        self.callManager.endCallAlls()
        self.webRTCManager?.close()
    }
    
    public func saveEndCall(_ uuid: String, _ reason: Int) {
        switch reason {
        case 1:
            self.sharedProvider?.reportCall(with: UUID(uuidString: uuid)!, endedAt: Date(), reason: CXCallEndedReason.failed)
            break
        case 2, 6:
            self.sharedProvider?.reportCall(with: UUID(uuidString: uuid)!, endedAt: Date(), reason: CXCallEndedReason.remoteEnded)
            break
        case 3:
            self.sharedProvider?.reportCall(with: UUID(uuidString: uuid)!, endedAt: Date(), reason: CXCallEndedReason.unanswered)
            break
        case 4:
            self.sharedProvider?.reportCall(with: UUID(uuidString: uuid)!, endedAt: Date(), reason: CXCallEndedReason.answeredElsewhere)
            break
        case 5:
            self.sharedProvider?.reportCall(with: UUID(uuidString: uuid)!, endedAt: Date(), reason: CXCallEndedReason.declinedElsewhere)
            break
        default:
            break
        }
    }
    
    
    func endCallNotExist(_ data: CallData) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(data.duration)) {
            let call = self.callManager.callWithUUID(uuid: UUID(uuidString: data.uuid)!)
            if (call != nil && self.answerCall == nil && self.outgoingCall == nil) {
                self.callEndTimeout(data)
                self.webRTCManager?.close()
            }
        }
    }
    
    
    
    func callEndTimeout(_ data: CallData) {
        self.saveEndCall(data.uuid, 3)
        guard let call = self.callManager.callWithUUID(uuid: UUID(uuidString: data.uuid)!) else {
            return
        }
        sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_TIMEOUT, data.toJSON())
        if let appDelegate = UIApplication.shared.delegate as? CallkitIncomingAppDelegate {
            appDelegate.onTimeOut(call)
        }
    }
    
    func getHandleType(_ handleType: String?) -> CXHandle.HandleType {
        var typeDefault = CXHandle.HandleType.generic
        switch handleType {
        case "number":
            typeDefault = CXHandle.HandleType.phoneNumber
            break
        case "email":
            typeDefault = CXHandle.HandleType.emailAddress
        default:
            typeDefault = CXHandle.HandleType.generic
        }
        return typeDefault
    }
    
    func initCallkitProvider(_ data: CallData) {
        if(self.sharedProvider == nil){
            self.sharedProvider = CXProvider(configuration: createConfiguration(data))
            self.sharedProvider?.setDelegate(self, queue: nil)
        }
        self.callManager.setSharedProvider(self.sharedProvider!)
    }
    
    func createConfiguration(_ data: CallData) -> CXProviderConfiguration {
        let configuration = CXProviderConfiguration(localizedName: data.appName)
        configuration.supportsVideo = data.supportsVideo
        configuration.maximumCallGroups = data.maximumCallGroups
        configuration.maximumCallsPerCallGroup = data.maximumCallsPerCallGroup
        
        configuration.supportedHandleTypes = [
            CXHandle.HandleType.generic,
            CXHandle.HandleType.emailAddress,
            CXHandle.HandleType.phoneNumber
        ]
        if #available(iOS 11.0, *) {
            configuration.includesCallsInRecents = data.includesCallsInRecents
        }
        if !data.iconName.isEmpty {
            if let image = UIImage(named: data.iconName) {
                configuration.iconTemplateImageData = image.pngData()
            } else {
                print("Unable to load icon \(data.iconName).");
            }
        }
        if !data.ringtonePath.isEmpty || data.ringtonePath != "system_ringtone_default"  {
            configuration.ringtoneSound = data.ringtonePath
        }
        return configuration
    }
    
    func sendDefaultAudioInterruptionNofificationToStartAudioResource(){
        var userInfo : [AnyHashable : Any] = [:]
        let intrepEndeRaw = AVAudioSession.InterruptionType.ended.rawValue
        userInfo[AVAudioSessionInterruptionTypeKey] = intrepEndeRaw
        userInfo[AVAudioSessionInterruptionOptionKey] = AVAudioSession.InterruptionOptions.shouldResume.rawValue
        NotificationCenter.default.post(name: AVAudioSession.interruptionNotification, object: self, userInfo: userInfo)
    }
    
    func configurAudioSession(){
        if data?.configureAudioSession != false {
            let session = AVAudioSession.sharedInstance()
            do{
                try session.setCategory(AVAudioSession.Category.playAndRecord, options: [
                    .allowBluetoothA2DP,
                    .duckOthers,
                    .allowBluetooth,
                ])
                
                try session.setMode(self.getAudioSessionMode(data?.audioSessionMode))
                try session.setActive(data?.audioSessionActive ?? true)
                try session.setPreferredSampleRate(data?.audioSessionPreferredSampleRate ?? 44100.0)
                try session.setPreferredIOBufferDuration(data?.audioSessionPreferredIOBufferDuration ?? 0.005)
            }catch{
                print(error)
            }
        }
    }
    
    func getAudioSessionMode(_ audioSessionMode: String?) -> AVAudioSession.Mode {
        var mode = AVAudioSession.Mode.default
        switch audioSessionMode {
        case "gameChat":
            mode = AVAudioSession.Mode.gameChat
            break
        case "measurement":
            mode = AVAudioSession.Mode.measurement
            break
        case "moviePlayback":
            mode = AVAudioSession.Mode.moviePlayback
            break
        case "spokenAudio":
            mode = AVAudioSession.Mode.spokenAudio
            break
        case "videoChat":
            mode = AVAudioSession.Mode.videoChat
            break
        case "videoRecording":
            mode = AVAudioSession.Mode.videoRecording
            break
        case "voiceChat":
            mode = AVAudioSession.Mode.voiceChat
            break
        case "voicePrompt":
            if #available(iOS 12.0, *) {
                mode = AVAudioSession.Mode.voicePrompt
            } else {
                // Fallback on earlier versions
            }
            break
        default:
            mode = AVAudioSession.Mode.default
        }
        return mode
    }
    
    public func providerDidReset(_ provider: CXProvider) {
        for call in self.callManager.calls {
            call.endCall()
        }
        self.callManager.removeAllCalls()
    }
    
    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        let call = Call(uuid: action.callUUID, data: self.data!, isOutGoing: true)
        call.handle = action.handle.value
        configurAudioSession()
        call.hasStartedConnectDidChange = { [weak self] in
            self?.sharedProvider?.reportOutgoingCall(with: call.uuid, startedConnectingAt: call.connectData)
        }
        call.hasConnectDidChange = { [weak self] in
            self?.sharedProvider?.reportOutgoingCall(with: call.uuid, connectedAt: call.connectedData)
        }
        self.outgoingCall = call;
        self.callManager.addCall(call)
        self.sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_START, self.data?.toJSON())
        action.fulfill()
    }
    
    
    
    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let call = self.callManager.callWithUUID(uuid: action.callUUID) else{
            action.fail()
            return
        }
        self.configurAudioSession()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1200)) {
            self.configurAudioSession()
        }
        call.hasConnectDidChange = { [weak self] in
            self?.sharedProvider?.reportOutgoingCall(with: call.uuid, connectedAt: call.connectedData)
        }
        self.answerCall = call
        sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_ACCEPT, self.data?.toJSON())
        if let appDelegate = UIApplication.shared.delegate as? CallkitIncomingAppDelegate {
            appDelegate.onAccept(call, action)
        }else {
            action.fulfill()
        }
    }

    public func onEndCall(hasCall: Bool, hasOutgoingCall: Bool, hasAnswerCall: Bool, data: CallData?) {
        if (hasCall == false) {
            if(hasAnswerCall == false && hasOutgoingCall == false){
                sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_TIMEOUT, data?.toJSON())
            } else {
                sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_ENDED, data?.toJSON())
            }
            return
        }
        if (hasAnswerCall == false && hasOutgoingCall == false) {
            sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_DECLINE, data?.toJSON())
            var url = data?.extra["callResponseUrl"] as? String
            let declineBody = data?.extra["declineBody"] as? String
            let sessionToken = data?.extra["sessionToken"] as? String
            if (url != nil) {
                if (sessionToken != nil) {
                    url = url! + "?sessionToken=" + sessionToken!
                }
                postRequest(url!, declineBody)
            }
        }else {
            sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_ENDED, data?.toJSON())
        }
        self.webRTCManager?.close()
    }
    
    
    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        guard let call = self.callManager.callWithUUID(uuid: action.callUUID) else {
            self.onEndCall(hasCall: false, hasOutgoingCall: self.outgoingCall != nil, hasAnswerCall: self.answerCall != nil, data: self.data)
            action.fail()
            return
        }
        call.endCall()
        self.callManager.removeCall(call)
        if (self.answerCall == nil && self.outgoingCall == nil) {
            if let appDelegate = UIApplication.shared.delegate as? CallkitIncomingAppDelegate {
                appDelegate.onDecline(call, action)
            } else {
                action.fulfill()
            }
        } else {
            if let appDelegate = UIApplication.shared.delegate as? CallkitIncomingAppDelegate {
                appDelegate.onEnd(call, action)
            } else {
                action.fulfill()
            }
        }
        self.onEndCall(hasCall: true, hasOutgoingCall: self.outgoingCall != nil, hasAnswerCall: self.answerCall != nil, data: self.data)
    }
    
    
    public func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        guard let call = self.callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        call.isOnHold = action.isOnHold
        call.isMuted = action.isOnHold
        self.callManager.setHold(call: call, onHold: action.isOnHold)
        sendHoldEvent(action.callUUID.uuidString, action.isOnHold)
        action.fulfill()
    }
    
    public func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        guard let call = self.callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        call.isMuted = action.isMuted
        sendMuteEvent(action.callUUID.uuidString, action.isMuted)
        action.fulfill()
    }
    
    public func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        guard (self.callManager.callWithUUID(uuid: action.callUUID)) != nil else {
            action.fail()
            return
        }
        self.sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_TOGGLE_GROUP, [ "id": action.callUUID.uuidString, "callUUIDToGroupWith" : action.callUUIDToGroupWith?.uuidString])
        action.fulfill()
    }
    
    public func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        guard (self.callManager.callWithUUID(uuid: action.callUUID)) != nil else {
            action.fail()
            return
        }
        self.sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_TOGGLE_DMTF, [ "id": action.callUUID.uuidString, "digits": action.digits, "type": action.type ])
        action.fulfill()
    }
    
    
    public func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        guard let call = self.callManager.callWithUUID(uuid: action.uuid) else {
            action.fail()
            return
        }
        sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_TIMEOUT, self.data?.toJSON())
        if let appDelegate = UIApplication.shared.delegate as? CallkitIncomingAppDelegate {
            appDelegate.onTimeOut(call)
        }
        action.fulfill()
    }
    
    public func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {

        if let appDelegate = UIApplication.shared.delegate as? CallkitIncomingAppDelegate {
            appDelegate.didActivateAudioSession(audioSession)
        }
        
        
            RTCAudioSession.sharedInstance().audioSessionDidActivate(audioSession)
            RTCAudioSession.sharedInstance().isAudioEnabled = true
        

        if(self.answerCall?.hasConnected ?? false){
            sendDefaultAudioInterruptionNofificationToStartAudioResource()
            return
        }
        if(self.outgoingCall?.hasConnected ?? false){
            sendDefaultAudioInterruptionNofificationToStartAudioResource()
            return
        }
        self.outgoingCall?.startCall(withAudioSession: audioSession) {success in
            if success {
                self.callManager.addCall(self.outgoingCall!)
                self.outgoingCall?.startAudio()
            }
        }
        self.answerCall?.ansCall(withAudioSession: audioSession) { success in
            if success{
                self.answerCall?.startAudio()
            }
        }
        sendDefaultAudioInterruptionNofificationToStartAudioResource()
        configurAudioSession()

        self.sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_TOGGLE_AUDIO_SESSION, [ "isActivate": true ])
    }
    
    public func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        
        if let appDelegate = UIApplication.shared.delegate as? CallkitIncomingAppDelegate {
            appDelegate.didDeactivateAudioSession(audioSession)
        }
        
        RTCAudioSession.sharedInstance().audioSessionDidDeactivate(audioSession)
        RTCAudioSession.sharedInstance().isAudioEnabled = false
        
        if self.outgoingCall?.isOnHold ?? false || self.answerCall?.isOnHold ?? false{
            print("Call is on hold")
            return
        }
        self.outgoingCall?.endCall()
        if(self.outgoingCall != nil){
            self.outgoingCall = nil
        }
        self.answerCall?.endCall()
        if(self.answerCall != nil){
            self.answerCall = nil
        }
        self.callManager.removeAllCalls()
        
        self.sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_TOGGLE_AUDIO_SESSION, [ "isActivate": false ])
    }
    
    public func sendMuteEvent(_ id: String, _ isMuted: Bool) {
        self.sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_TOGGLE_MUTE, [ "id": id, "isMuted": isMuted ])
    }
    
    public func sendHoldEvent(_ id: String, _ isOnHold: Bool) {
        self.sendEvent(SwiftFlutterCallkitIncomingPlugin.ACTION_CALL_TOGGLE_HOLD, [ "id": id, "isOnHold": isOnHold ])
    }
    
}
