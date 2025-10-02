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
}
