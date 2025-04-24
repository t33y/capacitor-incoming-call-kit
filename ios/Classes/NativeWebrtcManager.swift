//
//  CallManager.swift
//  flutter_callkit_incoming
//
//  Created by Hien Nguyen on 07/10/2021.
//

import Foundation
import CallKit
import WebRTC

protocol WebRTCClientDelegate: AnyObject {
    func webRTCClient(_ client: NativeWebrtcManager, didDiscoverLocalCandidate candidate: RTCIceCandidate)
    func webRTCClient(_ client: NativeWebrtcManager, didChangeConnectionState state: RTCIceConnectionState)
    func webRTCClient(_ client: NativeWebrtcManager, didReceiveData data: Data)
    
}

class NativeWebrtcManager: NSObject {

    // The `RTCPeerConnectionFactory` is in charge of creating new RTCPeerConnection instances.
      // A new RTCPeerConnection should be created every new call, but the factory is shared.
      private static let factory: RTCPeerConnectionFactory = {
          RTCInitializeSSL()
          let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
          let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
          return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
      }()
      
      weak var delegate: WebRTCClientDelegate?
      private let peerConnection: RTCPeerConnection
      private let rtcAudioSession =  RTCAudioSession.sharedInstance()
      private let audioQueue = DispatchQueue(label: "audio")
      private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                                     kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueFalse]
      private var videoCapturer: RTCVideoCapturer?
      private var localVideoTrack: RTCVideoTrack?
      private var remoteVideoTrack: RTCVideoTrack?
      private var localDataChannel: RTCDataChannel?
      private var remoteDataChannel: RTCDataChannel?

      @available(*, unavailable)
      override init() {
          fatalError("WebRTCClient:init is unavailable")
      }
      
      required init(iceServers:[RTCIceServer]) {
          let config = RTCConfiguration()
          config.iceServers = iceServers
          config.iceCandidatePoolSize = 10
          
          // Unified plan is more superior than planB
          config.sdpSemantics = .unifiedPlan
          
          // gatherContinually will let WebRTC to listen to any network changes and send any new candidates to the other client
          config.continualGatheringPolicy = .gatherContinually
          
          // Define media constraints. DtlsSrtpKeyAgreement is required to be true to be able to connect with web browsers.
          let constraints = RTCMediaConstraints(mandatoryConstraints: nil,
                                                optionalConstraints: ["DtlsSrtpKeyAgreement":kRTCMediaConstraintsValueTrue])
          
          guard let peerConnection = NativeWebrtcManager.factory.peerConnection(with: config, constraints: constraints, delegate: nil) else {
              fatalError("Could not create new RTCPeerConnection")
          }
          
          self.peerConnection = peerConnection
          super.init()
          self.createMediaSenders()
         self.configureAudioSession()
          self.peerConnection.delegate = self
      }
      
      // MARK: Signaling
      func offer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
          let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains,
                                               optionalConstraints: nil)
        
          self.peerConnection.offer(for: constrains) { (sdp, error) in
              guard let sdp = sdp else {
                  return
              }
              
              self.peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
                  completion(sdp)
              })
          }
      }
    
    func remoteDescriptionStatus()->String {
        let status = self.peerConnection.remoteDescription != nil ? "available" : "unavailable"
        return status

    }
      
    func answer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void)  {
          let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains,
                                               optionalConstraints: nil)
        
          self.peerConnection.answer(for: constrains) { (sdp, error) in

              guard let sdp = sdp else {
                  return
              }
              
            
              
              self.peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
                  completion(sdp)
              })
          }
      }
    
    func close()  {
        
        // 1. Clean up data channels
        self.localDataChannel?.close()
        self.localDataChannel?.delegate = nil
        self.localDataChannel = nil
        
        self.remoteDataChannel?.close()
        self.remoteDataChannel?.delegate = nil
        self.remoteDataChannel = nil
        
        // 2. Stop and remove video capturer
//        if let capturer = self.videoCapturer as? RTCCameraVideoCapturer {
//            capturer.stopCapture()
//        }
//        self.videoCapturer = nil
        
        // 3. Remove video tracks
//        self.localVideoTrack?.isEnabled = false
//        self.localVideoTrack = nil
//        
//        self.remoteVideoTrack?.isEnabled = false
//        self.remoteVideoTrack = nil
        
        // 4. Clean up peer connection
        self.peerConnection.delegate = nil
        
        // Close all transceivers
//        for transceiver in self.peerConnection.transceivers {
//            let sender = transceiver.sender
//            if let track = sender.track {  // Only track is optional
//                track.isEnabled = false
//
//            }
//            self.peerConnection.removeTrack(sender)
//        }
        
        self.peerConnection.close()
        
        // 5. Reset audio session
//        self.audioQueue.async { [weak self] in
//            guard let self = self else { return }
//            self.rtcAudioSession.lockForConfiguration()
//            do {
//                RTCAudioSession.sharedInstance().isAudioEnabled = false
//                try self.rtcAudioSession.setActive(false)
//            } catch {
//                debugPrint("Error deactivating audio session: \(error)")
//            }
//            self.rtcAudioSession.unlockForConfiguration()
//        }
//        
        // 6. Clear all delegates
//        self.delegate = nil
      }

      
      func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> ()) {
          if peerConnection.signalingState == .stable {
              // If in stable state, check if a remote description is already set
              if peerConnection.remoteDescription == nil {
                  self.peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
                  debugPrint("Set remote sdp: \(remoteSdp.type) connection state: \(peerConnection.connectionState) signal state: \(peerConnection.signalingState)")
              } else {
                  // Remote description is already set
                  print("Cannot set remote description in stable state as one is already set.")
              }
          } else {
              self.peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
              debugPrint("Set remote sdp: \(remoteSdp.type) connection state: \(peerConnection.connectionState) signal state: \(peerConnection.signalingState)")
          }
      }
      
      func set(remoteCandidate: RTCIceCandidate, completion: @escaping (Error?) -> ()) {
          self.peerConnection.add(remoteCandidate, completionHandler: completion)
      }
      
      // MARK: Media
      func startCaptureLocalVideo(renderer: RTCVideoRenderer) {
          guard let capturer = self.videoCapturer as? RTCCameraVideoCapturer else {
              return
          }

          guard
              let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }),
          
              // choose highest res
              let format = (RTCCameraVideoCapturer.supportedFormats(for: frontCamera).sorted { (f1, f2) -> Bool in
                  let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
                  let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
                  return width1 < width2
              }).last,
          
              // choose highest fps
              let fps = (format.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }.last) else {
              return
          }

          capturer.startCapture(with: frontCamera,
                                format: format,
                                fps: Int(fps.maxFrameRate))
          
          self.localVideoTrack?.add(renderer)
      }
      
      func renderRemoteVideo(to renderer: RTCVideoRenderer) {
          self.remoteVideoTrack?.add(renderer)
      }
      
      private func configureAudioSession() {
          self.rtcAudioSession.lockForConfiguration()
          do {
              try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord)
              try self.rtcAudioSession.setMode(AVAudioSession.Mode.voiceChat)
              RTCAudioSession.sharedInstance().useManualAudio = true
              RTCAudioSession.sharedInstance().isAudioEnabled = false
          } catch let error {
              debugPrint("Error changeing AVAudioSession category: \(error)")
          }
          self.rtcAudioSession.unlockForConfiguration()
      }
      
      private func createMediaSenders() {
          let streamId = "stream"
          
          // Audio
          let audioTrack = self.createAudioTrack()
          self.peerConnection.add(audioTrack, streamIds: [streamId])
          
          // Video
//          let videoTrack = self.createVideoTrack()
//          self.localVideoTrack = videoTrack
//          self.peerConnection.add(videoTrack, streamIds: [streamId])
//          self.remoteVideoTrack = self.peerConnection.transceivers.first { $0.mediaType == .video }?.receiver.track as? RTCVideoTrack
//          
          // Data
          if let dataChannel = createDataChannel() {
              dataChannel.delegate = self
              self.localDataChannel = dataChannel
          }
      }
      
      private func createAudioTrack() -> RTCAudioTrack {
          let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
          let audioSource = NativeWebrtcManager.factory.audioSource(with: audioConstrains)
          let audioTrack = NativeWebrtcManager.factory.audioTrack(with: audioSource, trackId: "audio0")
          return audioTrack
      }
      
      private func createVideoTrack() -> RTCVideoTrack {
          let videoSource = NativeWebrtcManager.factory.videoSource()
          
          #if targetEnvironment(simulator)
          self.videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
          #else
          self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
          #endif
          
          let videoTrack = NativeWebrtcManager.factory.videoTrack(with: videoSource, trackId: "video0")
          return videoTrack
      }
      
      // MARK: Data Channels
      private func createDataChannel() -> RTCDataChannel? {
          let config = RTCDataChannelConfiguration()
          guard let dataChannel = self.peerConnection.dataChannel(forLabel: "WebRTCData", configuration: config) else {
              debugPrint("Warning: Couldn't create data channel.")
              return nil
          }
          return dataChannel
      }
      
      func sendData(_ data: Data) {
          let buffer = RTCDataBuffer(data: data, isBinary: true)
          self.remoteDataChannel?.sendData(buffer)
      }
}

// MARK: PeerConnection delegate
extension NativeWebrtcManager: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        debugPrint("peerConnection new signaling state: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        debugPrint("peerConnection did add stream")
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        debugPrint("peerConnection did remove stream")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        debugPrint("peerConnection should negotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        debugPrint("peerConnection new connection state: \(newState)")
        self.delegate?.webRTCClient(self, didChangeConnectionState: newState)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        debugPrint("peerConnection new gathering state: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        debugPrint("peerConnection did generate candidate(s)")
        self.delegate?.webRTCClient(self, didDiscoverLocalCandidate: candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        debugPrint("peerConnection did remove candidate(s)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        debugPrint("peerConnection did open data channel")
//        self.remoteDataChannel = dataChannel
    }
}


extension NativeWebrtcManager {
    private func setTrackEnabled<T: RTCMediaStreamTrack>(_ type: T.Type, isEnabled: Bool) {
        peerConnection.transceivers
            .compactMap { return $0.sender.track as? T }
            .forEach { $0.isEnabled = isEnabled }
    }
}

// MARK: - Video control
extension NativeWebrtcManager {
    func hideVideo() {
        self.setVideoEnabled(false)
    }
    func showVideo() {
        self.setVideoEnabled(true)
    }
    private func setVideoEnabled(_ isEnabled: Bool) {
        setTrackEnabled(RTCVideoTrack.self, isEnabled: isEnabled)
    }
}
// MARK:- Audio control
extension NativeWebrtcManager {
    func muteAudio() {
        self.setAudioEnabled(false)
    }
    
    func unmuteAudio() {
        self.setAudioEnabled(true)
    }
    
    // Fallback to the default playing device: headphones/bluetooth/ear speaker
    func speakerOff() {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord)
                try self.rtcAudioSession.overrideOutputAudioPort(.none)
            } catch let error {
                debugPrint("Error setting AVAudioSession category: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    // Force speaker
    func speakerOn() {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord)
                try self.rtcAudioSession.overrideOutputAudioPort(.speaker)
                try self.rtcAudioSession.setActive(true)
            } catch let error {
                debugPrint("Couldn't force audio to speaker: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    private func setAudioEnabled(_ isEnabled: Bool) {
        setTrackEnabled(RTCAudioTrack.self, isEnabled: isEnabled)
    }
}

extension NativeWebrtcManager: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        debugPrint("dataChannel did change state: \(dataChannel.readyState)")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
//        self.delegate?.webRTCClient(self, didReceiveData: buffer.data)
    }
}
