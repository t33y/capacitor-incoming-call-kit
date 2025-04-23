//
//  IntentHandler.swift
//
//
//  Created by Omotayo Olarewaju on 26/02/2025.
//

import Foundation
import Intents

extension Notification.Name {
    static let videoCallRequested = Notification.Name("videoCallRequested")
}

class IntentHandler: INExtension {
    
    func confirm(intent: INStartCallIntent, completion: @escaping (INStartCallIntentResponse) -> Void) {
        
        guard let contact = intent.contacts?.first else {
            completion(INStartCallIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
         let response = INStartCallIntentResponse(code: .ready, userActivity: nil)
        let contactName = contact.personHandle?.value ?? "Unknown"
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .videoCallRequested, object: nil, userInfo: ["contact": contactName])
        }

         completion(response)
     }
     
    func handle(intent: INStartCallIntent, completion: @escaping (INStartCallIntentResponse) -> Void) {
         if intent.callCapability == .videoCall{
             guard let contact = intent.contacts?.first else {
                 completion(INStartCallIntentResponse(code: .failure, userActivity: nil))
                 return
             }
             
             let contactName = contact.displayName
             DispatchQueue.main.async {
                 NotificationCenter.default.post(name: .videoCallRequested, object: nil, userInfo: ["contact": contactName])
             }
 
             let response = INStartCallIntentResponse(code: .ready , userActivity: nil)
             completion(response)
         } else {
             completion(INStartCallIntentResponse(code: .failure, userActivity: nil))
             return
         }

     }
}

