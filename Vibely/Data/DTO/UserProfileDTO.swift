//
//  UserProfileDTO.swift
//  Vibely
//
//  Created by Muhammad Saif on 22/01/26.
//

import Foundation
import FirebaseFirestore

struct UserProfileDTO: Identifiable, Codable {
    @DocumentID var id: String?
    
    var username: String
    var username_lowercase: String
    var email: String?
    var phoneNumber: String?
    var photoURL: String?
    var coverPhotoURL: String?
    var collectionPhotos: [String]?
    
    var profession: String?
    var age: String?
    var gender: String?
    var fcmToken: String?
    var bio: String?
    var displayName: String?
    var location: String?
    
    var coverPhotoHash: String?
    var profilePhotoHash: String?
    
    var createdAt: Date?
    var updatedAt: Date?
}
