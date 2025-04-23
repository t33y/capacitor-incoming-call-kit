//
//  CallIntentHandler.swift
//
//
//  Created by Omotayo Olarewaju on 26/02/2025.
//

import Foundation
import Intents

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any? {
        if let startCallIntent = intent as? INStartCallIntent,
           startCallIntent.callCapability == .videoCall {
            return SwiftFlutterCallkitIncomingPlugin // Return a dedicated handler for video calls
        }
        return self // Default handler if not a video call
    }
}

