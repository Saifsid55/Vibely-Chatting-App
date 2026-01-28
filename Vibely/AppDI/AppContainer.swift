//
//  AppContainer.swift
//  Vibely
//
//  Created by Muhammad Saif on 22/01/26.
//
// MARK: - Compositional Root

import Foundation
import FirebaseFirestore

final class AppContainer {

    // MARK: - Singletons
    private lazy var firestore: Firestore = {
        Firestore.firestore()
    }()

    private lazy var cloudinaryService: CloudinaryService = {
        AppEnvironment.shared.cloudinaryService
    }()

    // MARK: - Repositories
    private lazy var profileRepository: ProfileRepository = {
        FirebaseProfileRepository(db: firestore)
    }()

    // MARK: - Services
    private lazy var profileImageService: ProfileImageService = {
        CloudinaryProfileImageService(cloudinary: cloudinaryService)
    }()

    // MARK: - UseCases
    private lazy var fetchProfileUseCase: FetchProfileUseCase = {
        FetchProfileUseCase(repository: profileRepository)
    }()

    private lazy var updateProfileUseCase: UpdateProfileDetailsUseCase = {
        UpdateProfileDetailsUseCase(repository: profileRepository)
    }()

    private lazy var uploadImageUseCase: UploadProfileImageUseCase = {
        UploadProfileImageUseCase(
            imageService: profileImageService,
            repository: profileRepository
        )
    }()

    // MARK: - ViewModels
    @MainActor
    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            fetchProfileUseCase: fetchProfileUseCase,
            uploadImageUseCase: uploadImageUseCase,
            updateProfileUseCase: updateProfileUseCase
        )
    }
}
