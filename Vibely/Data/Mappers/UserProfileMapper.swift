//
//  UserProfileMapper.swift
//  Vibely
//
//  Created by Muhammad Saif on 22/01/26.
//

extension UserProfile {
    init(dto: UserProfileDTO) {
        self.init(
            id: dto.id ?? "",
            
            username: dto.username,
            usernameLowercase: dto.username_lowercase,
            
            email: dto.email,
            phoneNumber: dto.phoneNumber,
            
            photoURL: dto.photoURL,
            coverPhotoURL: dto.coverPhotoURL,
            collectionPhotos: dto.collectionPhotos ?? [],
            
            profession: dto.profession,
            age: dto.age,
            gender: dto.gender,
            fcmToken: dto.fcmToken,
            
            bio: dto.bio,
            displayName: dto.displayName,
            location: dto.location,
            
            coverPhotoHash: dto.coverPhotoHash,
            profilePhotoHash: dto.profilePhotoHash,
            
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }
}

