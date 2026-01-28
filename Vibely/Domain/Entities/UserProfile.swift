//
//  UserProfile.swift
//  Vibely
//
//  Created by Muhammad Saif on 22/01/26.
//

// Domain/Entities/UserProfile.swift

import Foundation

struct UserProfile: Identifiable {
    let id: String

    let username: String
    let usernameLowercase: String

    let email: String?
    let phoneNumber: String?

    let photoURL: String?
    let coverPhotoURL: String?
    let collectionPhotos: [String]

    let profession: String?
    let age: String?
    let gender: String?
    let fcmToken: String?

    let bio: String?
    let displayName: String?
    let location: String?

    let coverPhotoHash: String?
    let profilePhotoHash: String?

    let createdAt: Date?
    let updatedAt: Date?
}

