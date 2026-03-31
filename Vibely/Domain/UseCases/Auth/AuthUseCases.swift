import Foundation

struct AuthUseCases {
    let authRepository: AuthRepository
    let userRepository: UserProfileRepository

    func login(email: String, password: String) async throws -> AppUserModel? {
        let uid = try await authRepository.signIn(email: email, password: password)
        return try await userRepository.fetchUser(uid: uid)
    }

    func signup(email: String, password: String) async throws -> String {
        try await authRepository.signUp(email: email, password: password)
    }

    func loadCurrentUser() async throws -> AppUserModel? {
        guard let uid = authRepository.currentUserID() else { return nil }
        return try await userRepository.fetchUser(uid: uid)
    }
}
