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
    var collectionPhotos: [String]?

    var profession: String?
    var age: String?
    var gender: String?
    var fcmToken: String?
    var bio: String?
    var displayName: String?
    var location: String?        
    var coverPhotoHash: String?      // <--- ADD THIS
    var profilePhotoHash: String?
    var createdAt: Date?          // Firestore Timestamp → Date (OK)
    var updatedAt: Date?
}
