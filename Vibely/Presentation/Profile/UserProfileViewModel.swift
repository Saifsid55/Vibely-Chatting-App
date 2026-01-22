//
//  ProfileViewModel.swift
//  Vibely
//
//  Created by Muhammad Saif on 22/01/26.
//

@MainActor
extension ProfileViewModel {
    
    func updateProfileDetails(
        name: String,
        bio: String,
        location: String,
        gender: String,
        age: String,
        profession: String
    ) async {
        
        let details = ProfileUpdateDetails(
            name: name,
            bio: bio,
            age: age,
            profession: profession,
            location: location
        )
        
        await updateProfile(details: details)
    }
}
