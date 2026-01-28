//
//  ProfileViewModel.swift
//  Vibely
//
//  Created by Mohd Saif on 13/11/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import _PhotosUI_SwiftUI
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {
    
    @Published private(set) var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let fetchProfileUseCase: FetchProfileUseCase
    private let uploadImageUseCase: UploadProfileImageUseCase
    private let updateProfileUseCase: UpdateProfileDetailsUseCase
    
    init(
        fetchProfileUseCase: FetchProfileUseCase,
        uploadImageUseCase: UploadProfileImageUseCase,
        updateProfileUseCase: UpdateProfileDetailsUseCase
    ) {
        self.fetchProfileUseCase = fetchProfileUseCase
        self.uploadImageUseCase = uploadImageUseCase
        self.updateProfileUseCase = updateProfileUseCase
    }
    
    func loadProfile(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            profile = try await fetchProfileUseCase.execute(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func uploadImage(
        data: Data,
        type: ProfileImageType
    ) async {
        guard let profile else { return }
        
        do {
            try await uploadImageUseCase.execute(
                userId: profile.id,
                imageData: data,
                type: type,
                existingHash: type == .profile
                ? profile.profilePhotoHash
                : profile.coverPhotoHash
            )
            
            await loadProfile(userId: profile.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateProfile(details: ProfileUpdateDetails) async {
        guard let profile else { return }
        
        do {
            try await updateProfileUseCase.execute(
                userId: profile.id,
                details: details
            )
            await loadProfile(userId: profile.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
