import Foundation
import FirebaseFirestore

final class AppContainer {
    private lazy var firestore: Firestore = { Firestore.firestore() }()
    private lazy var cloudinaryService: CloudinaryService = { AppEnvironment.shared.cloudinaryService }()

    private lazy var authRepository: AuthRepository = { FirebaseAuthRepository() }()
    private lazy var userRepository: UserProfileRepository = { FirebaseUserProfileRepository(db: firestore) }()
    private lazy var chatRepository: ChatRepository = { FirebaseChatRepository(db: firestore) }()
    private lazy var profileRepository: ProfileRepository = { FirebaseProfileRepository(db: firestore) }()

    private lazy var profileImageService: ProfileImageService = { CloudinaryProfileImageService(cloudinary: cloudinaryService) }()

    private lazy var fetchProfileUseCase: FetchProfileUseCase = { FetchProfileUseCase(repository: profileRepository) }()
    private lazy var updateProfileUseCase: UpdateProfileDetailsUseCase = { UpdateProfileDetailsUseCase(repository: profileRepository) }()
    private lazy var uploadImageUseCase: UploadProfileImageUseCase = {
        UploadProfileImageUseCase(imageService: profileImageService, repository: profileRepository)
    }()

    @MainActor
    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authRepository: authRepository, userRepository: userRepository)
    }

    @MainActor
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(chatRepository: chatRepository)
    }

    @MainActor
    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            fetchProfileUseCase: fetchProfileUseCase,
            uploadImageUseCase: uploadImageUseCase,
            updateProfileUseCase: updateProfileUseCase
        )
    }
}
