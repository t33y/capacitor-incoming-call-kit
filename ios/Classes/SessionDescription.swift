//
//  SessionDescription.swift
//
//
//  Created by Omotayo Olarewaju on 22/02/2025.
//

import Foundation
import WebRTC

//extension RTCSdpType {
//    init?(from string: String) {
//        switch string.lowercased() {
//        case "offer":
//            self = .offer
//        case "pranswer":
//            self = .prAnswer
//        case "answer":
//            self = .answer
//        case "rollback":
//            self = .rollback
//        default:
//            return nil
//        }
//    }

enum SdpType: String, Codable {
    case offer, prAnswer, answer, rollback
    
    var rtcSdpType: RTCSdpType {
        switch self {
        case .offer:    return .offer
        case .answer:   return .answer
        case .prAnswer: return .prAnswer
        case .rollback: return .rollback
        }
    }
    // Initializer to convert from String to SdpType
    init?(from string: String) {
        switch string.lowercased() {
        case "offer": self = .offer
        case "pranswer": self = .prAnswer
        case "answer": self = .answer
        case "rollback": self = .rollback
        default: return nil
        }
    }
}

/// This struct is a swift wrapper over `RTCSessionDescription` for easy encode and decode
struct SessionDescription: Codable {
    let sdp: String
    let type: SdpType
    
    init(from rtcSessionDescription: RTCSessionDescription) {
        self.sdp = rtcSessionDescription.sdp
        
        switch rtcSessionDescription.type {
        case .offer:    self.type = .offer
        case .prAnswer: self.type = .prAnswer
        case .answer:   self.type = .answer
        case .rollback: self.type = .rollback
        @unknown default:
            fatalError("Unknown RTCSessionDescription type: \(rtcSessionDescription.type.rawValue)")
        }
    }
    
    var rtcSessionDescription: RTCSessionDescription {
        return RTCSessionDescription(type: self.type.rtcSdpType, sdp: self.sdp)
    }
}
