//
//  ProfileRepository.swift
//  Vibely
//
//  Created by Muhammad Saif on 22/01/26.
//
import Foundation


protocol ProfileRepository {
    func fetchProfile(userId: String) async throws -> UserProfile
    func updateProfileDetails(
        userId: String,
        details: ProfileUpdateDetails
    ) async throws
    
    func updateImage(
        userId: String,
        type: ProfileImageType,
        imageURL: String,
        imageHash: String?
    ) async throws
}
