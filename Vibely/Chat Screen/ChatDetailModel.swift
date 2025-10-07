//
//  ChatDetailModel.swift
//  Vibely
//
//  Created by Mohd Saif on 17/09/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct Message: Identifiable, Codable, Hashable {
    @DocumentID var id: String?           // Firestore document ID
    var text: String?
    var senderId: String                   // Firestore UID of sender
    var timestamp: Date
    var type: String                       // "text", "image", "audio"
    
    // Computed property to check if this message was sent by current user
    var isMe: Bool {
        senderId == Auth.auth().currentUser?.uid
    }
    
    // Optional enum for UI convenience
    var messageType: MessageTypeEnum {
        return MessageTypeEnum(rawValue: type) ?? .text
    }
}

enum MessageTypeEnum: String, Codable {
    case text
    case image
    case audio
}
