//
//  ProfileModel.swift
//  Vibely
//
//  Created by Mohd Saif on 13/11/25.
//

import Foundation
import FirebaseFirestore

struct UserProfileModel: Identifiable, Codable {
    @DocumentID var id: String?
    var username: String
    var username_lowercase: String
    var email: String?
    var phoneNumber: String?
    var photoURL: String?
    var coverPhotoURL: String?
    var collectionPhotos: [String]? // Array of image URLs
    var profession: String?
    var age: Int?
    var gender: String?
    var fcmToken: String?
    var bio: String?
    // Timestamps
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}
