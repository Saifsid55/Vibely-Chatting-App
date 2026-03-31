import Foundation
import FirebaseFirestore

@MainActor
final class AuthViewModel: AuthViewModelProtocol {
    @Published var email = ""
    @Published var password = ""
    @Published var phoneNumber = ""
    @Published var otpCode = ""
    @Published var username = ""
    @Published var currentUser: AppUserModel?
    @Published var isAuthenticated = false
    @Published var showUsernameScreen = false
    @Published var errorMessage: String?
    @Published var confirmPassword = ""
    @Published var isLoading = true
    @Published var verificationID: String?
    @Published var profileImageURL: String?

    private let authRepository: AuthRepository
    private let userRepository: UserProfileRepository
    private let authUseCases: AuthUseCases

    private let defaultUserSchema: [String: Any] = [
        "age": "",
        "bio": "",
        "collectionPhotos": [],
        "coverPhotoURL": "",
        "displayName": "",
        "fcmToken": "",
        "gender": "",
        "location": "",
        "phoneNumber": "",
        "coverPhotoHash": "",
        "profilePhotoHash": "",
        "photoURL": "",
        "profession": "",
        "updatedAt": FieldValue.serverTimestamp(),
        "username_lowercase": ""
    ]

    var isPasswordMatching: Bool {
        !password.isEmpty && password == confirmPassword
    }

    init(
        authRepository: AuthRepository,
        userRepository: UserProfileRepository
    ) {
        self.authRepository = authRepository
        self.userRepository = userRepository
        self.authUseCases = AuthUseCases(authRepository: authRepository, userRepository: userRepository)
        checkCurrentUser()
    }

    convenience init() {
        let firestore = Firestore.firestore()
        self.init(
            authRepository: FirebaseAuthRepository(),
            userRepository: FirebaseUserProfileRepository(db: firestore)
        )
    }

    func checkCurrentUser() {
        guard let uid = authRepository.currentUserID() else {
            isLoading = false
            return
        }

        Task {
            do {
                currentUser = try await authUseCases.loadCurrentUser()
                isAuthenticated = currentUser != nil
                await userRepository.syncUserSchema(uid: uid, schema: defaultUserSchema)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func signupWithEmail() async throws {
        guard isPasswordMatching else {
            errorMessage = "Passwords do not match"
            return
        }

        do {
            let uid = try await authUseCases.signup(email: email, password: password)
            await checkUserExistsOrNavigate(uid: uid, email: email, phone: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loginWithEmail() async {
        do {
            currentUser = try await authUseCases.login(email: email, password: password)
            isAuthenticated = currentUser != nil
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendOTP(to phoneNumber: String) async throws -> String {
        let verificationID = try await authRepository.sendOTP(to: phoneNumber)
        self.verificationID = verificationID
        return verificationID
    }

    func verifyOTP(_ code: String) async throws {
        guard let verificationID else { return }
        try await authRepository.verifyOTP(verificationID: verificationID, code: code)
    }

    func checkUsernameAvailable() async -> Bool {
        do {
            return try await userRepository.isUsernameAvailable(username)
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func createUserProfile(uid: String, email: String?, phone: String?) async {
        let user = AppUserModel(id: uid, email: email, phoneNumber: phone, username: username)
        do {
            try await userRepository.saveUser(user, uid: uid)
            try await userRepository.updateUsernameLowercase(uid: uid, username: username)
            currentUser = user
            isAuthenticated = true
            showUsernameScreen = false
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func checkUserExistsOrNavigate(uid: String, email: String?, phone: String?) async {
        do {
            if let user = try await userRepository.fetchUser(uid: uid) {
                currentUser = user
                isAuthenticated = true
                isLoading = false
            } else {
                showUsernameScreen = true
                isLoading = false
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func syncUserSchema(for userID: String) {
        Task {
            await userRepository.syncUserSchema(uid: userID, schema: defaultUserSchema)
        }
    }

    func signOut() {
        do {
            try authRepository.signOut()
            currentUser = nil
            isAuthenticated = false
            NotificationCenter.default.post(name: .didLogout, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteUserAccount() async throws {
        guard let uid = authRepository.currentUserID() else {
            throw NSError(domain: "DeleteAccount", code: 0, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }

        let db = Firestore.firestore()
        try await userRepository.deleteUserDocument(uid: uid)

        let chatsQuery = try await db.collection("chats")
            .whereField("participants", arrayContains: uid)
            .getDocuments()

        for chatDoc in chatsQuery.documents {
            let chatRef = chatDoc.reference
            let messagesSnapshot = try await chatRef.collection("messages").getDocuments()
            for messageDoc in messagesSnapshot.documents where messageDoc.data()["senderId"] as? String == uid {
                try await messageDoc.reference.delete()
            }
            try await chatRef.updateData(["participants": FieldValue.arrayRemove([uid])])
        }

        try await authRepository.deleteCurrentUser()
    }

    func resetFields() {
        email = ""
        password = ""
        username = ""
        otpCode = ""
        phoneNumber = ""
        errorMessage = nil
        confirmPassword = ""
    }
}

extension Notification.Name {
    static let didLogout = Notification.Name("didLogout")
    static let profileTabDidDisappear = Notification.Name("profileTabDidDisappear")
}
