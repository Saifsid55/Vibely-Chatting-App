//
//  EditProfileViewModel.swift
//  Vibely
//
//  Created by Mohd Saif on 15/11/25.
//

import SwiftUI

@MainActor
final class EditProfileDetailsViewModel: ObservableObject {
    
    // Editable fields
    @Published var fullName: String = ""
    @Published var bio: String = ""
    @Published var gender: String = ""
    @Published var age: String = ""
    @Published var location: String = ""
    @Published var profession: String = ""
    
    // NON-editable fields
    @Published var phoneNumber: String = ""
    @Published var email: String = ""
    @Published var usernameLowercase: String = ""
    
    @Published var isSaving = false
    
    private var profileVM: ProfileViewModel
    
    init(profileVM: ProfileViewModel) {
        self.profileVM = profileVM
        
        // Load from profile model
        let p = profileVM.profile
        
        self.fullName = p?.displayName ?? ""
        self.bio = p?.bio ?? ""
        self.gender = p?.gender ?? ""
        self.age = p?.age ?? ""
        self.location = p?.location ?? ""
        self.profession = p?.profession ?? ""
        
        // NON editable:
        self.phoneNumber = p?.phoneNumber ?? ""
        self.email = p?.email ?? ""
        self.usernameLowercase = p?.username_lowercase ?? ""
    }
    
    func loadFromProfile() {
        guard let p = profileVM.profile else { return }
        
        // Editable
        fullName = p.displayName ?? ""
        bio = p.bio ?? ""
        gender = p.gender ?? ""
        age = p.age ?? ""
        location = p.location ?? ""
        profession = p.profession ?? ""
        
        // Non-editable
        phoneNumber = p.phoneNumber ?? ""
        email = p.email ?? ""
        usernameLowercase = p.username_lowercase
    }
    
    func saveChanges() async throws {
        isSaving = true
        defer { isSaving = false }
        
        // Save only editable fields
        await profileVM.updateProfileDetails(
            name: fullName,
            bio: bio,
            location: location,
            gender: gender,
            age: age,
            profession: profession
        )
    }
}
