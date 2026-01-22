//
//  FirebaseProfileRepository.swift
//  Vibely
//
//  Created by Muhammad Saif on 22/01/26.
//

import FirebaseFirestore

enum ProfileRepositoryError: Error {
    case profileNotFound
}

final class FirebaseProfileRepository: ProfileRepository {
    
    private let db: Firestore
    private let usersCollection = "users"
    
    init(db: Firestore = .firestore()) {
        self.db = db
    }
    
    func fetchProfile(userId: String) async throws -> UserProfile {
        let doc = try await db
            .collection(usersCollection)
            .document(userId)
            .getDocument()
        
        guard doc.exists else {
            throw ProfileRepositoryError.profileNotFound
        }
        
        let dto = try doc.data(as: UserProfileDTO.self)
        return UserProfile(dto: dto)
    }
    
    func updateProfileDetails(
        userId: String,
        details: ProfileUpdateDetails
    ) async throws {
        try await db
            .collection(usersCollection)
            .document(userId)
            .updateData([
                "displayName": details.name,
                "bio": details.bio,
                "age": details.age,
                "profession": details.profession,
                "location": details.location,
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }
    
    func updateImage(
        userId: String,
        type: ProfileImageType,
        imageURL: String,
        imageHash: String?
    ) async throws {
        
        var updateData: [String: Any] = [
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        switch type {
        case .profile:
            updateData["photoURL"] = imageURL
            updateData["profilePhotoHash"] = imageHash
            
        case .cover:
            updateData["coverPhotoURL"] = imageURL
            updateData["coverPhotoHash"] = imageHash
        }
        
        try await db
            .collection(usersCollection)
            .document(userId)
            .updateData(updateData)
    }
}
