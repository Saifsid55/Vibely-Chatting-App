//
//  Untitled.swift
//  Vibely
//
//  Created by Mohd Saif on 02/10/25.
//

import Foundation
import FirebaseFirestore

struct AppUserModel: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var email: String?
    var phoneNumber: String?
    var username: String
    var createdAt: Date = Date()
    var avatarURL: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AppUserModel, rhs: AppUserModel) -> Bool {
        lhs.id == rhs.id
    }
}
