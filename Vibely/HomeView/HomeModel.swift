//
//  HomeModel.swift
//  Vibely
//
//  Created by Mohd Saif on 06/09/25.
//

import Foundation
import FirebaseFirestore

struct Chat: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var participants: [String]           // Match Firestore key
    var avatarURL: String?
    var lastMessage: LastMessage?        // Nested struct
}

struct LastMessage: Codable, Hashable {
    var text: String
    var senderId: String
    var timestamp: Date
}
