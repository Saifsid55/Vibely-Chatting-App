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
    var participants: [String]
    var avatarURL: [String: String]?   // optional: [uid: avatarURL]
    var lastMessage: LastMessage?
    
    func displayName(for currentUid: String, allUsers: [String: AppUserModel]) -> String {
        // Get the other participant's ID
        guard let otherId = participants.first(where: { $0 != currentUid }) else { return "Unknown" }
        return allUsers[otherId]?.username ?? "Unknown"
    }
    
    func displayAvatar(for currentUid: String) -> String? {
        guard let avatars = avatarURL,
              let otherId = participants.first(where: { $0 != currentUid }) else { return nil }
        return avatars[otherId]
    }
}

struct LastMessage: Codable, Hashable {
    var text: String
    var senderId: String
    var timestamp: Date
}
