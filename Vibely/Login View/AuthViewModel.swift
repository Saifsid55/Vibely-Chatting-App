//
//  UserProfileViewModel.swift
//  Vibely
//
//  Created by Mohd Saif on 02/10/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
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
    @Published var profileImageURL: String? = nil
    
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
        "photoURL": "",
        "profession": "",
        "updatedAt": FieldValue.serverTimestamp()
    ]
    
    private let db = Firestore.firestore()
    
    var isPasswordMatching: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    init() {
        checkCurrentUser()
    }
    
    func checkCurrentUser() {
        if let user = Auth.auth().currentUser {
            Task {
                try await loadUser(uid: user.uid)
                self.syncUserSchema(for: user.uid)
            }
        } else {
            // 👇 Add this to end splash for non-logged-in users
            self.isLoading = false
        }
        
    }
    
    
    // MARK: - Email Auth
    func signupWithEmail() async throws {
        guard isPasswordMatching else {
            errorMessage = "Passwords do not match"
            return
        }
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.checkUserExistsOrNavigate(uid: result.user.uid, email: email, phone: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loginWithEmail() async {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            try await loadUser(uid: result.user.uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Phone Auth
    func sendOTP(to phoneNumber: String) async throws -> String {
        let formattedPhone = "+91" + phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !phoneNumber.isEmpty else {
            throw NSError(domain: "AuthError", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Phone number cannot be empty"])
        }
        
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(formattedPhone, uiDelegate: nil) { verificationID, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let verificationID = verificationID else {
                    continuation.resume(throwing: NSError(domain: "AuthError", code: 0,
                                                          userInfo: [NSLocalizedDescriptionKey: "Failed to get verification ID"]))
                    return
                }
                
                self?.verificationID = verificationID
                continuation.resume(returning: verificationID)
            }
        }
    }
    
    func verifyOTP(_ code: String) async throws {
        guard let verificationID = verificationID else { return }
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        
        _ = try await Auth.auth().signIn(with: credential)
    }
    
    // MARK: - Username Check & Creation
    func checkUsernameAvailable() async -> Bool {
        do {
            let snapshot = try await db.collection("users")
                .whereField("username", isEqualTo: username)
                .getDocuments()
            return snapshot.documents.isEmpty
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func createUserProfile(uid: String, email: String?, phone: String?) async {
        let user = AppUserModel(id: uid, email: email, phoneNumber: phone, username: username)
        do {
            try db.collection("users").document(uid).setData(from: user)
            
            try await db.collection("users").document(uid).updateData([
                "username_lowercase": username.lowercased()
            ])
            currentUser = user
            isAuthenticated = true
            showUsernameScreen = false
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Helpers
    private func checkUserExistsOrNavigate(uid: String, email: String?, phone: String?) {
        Task {
            do {
                let doc = try await db.collection("users").document(uid).getDocument()
                if doc.exists {
                    if let user = try? doc.data(as: AppUserModel.self) {
                        await MainActor.run {
                            self.currentUser = user
                            self.isAuthenticated = true
                            self.isLoading = false
                        }
                    }
                } else {
                    await MainActor.run {
                        self.showUsernameScreen = true
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadUser(uid: String) async throws {
        let doc = try await db.collection("users").document(uid).getDocument()
        if let user = try? doc.data(as: AppUserModel.self) {
            currentUser = user
            isAuthenticated = true
            self.isLoading = false
        }
    }
    
    func syncUserSchema(for userID: String) {
        let userRef = db.collection("users").document(userID)
        
        // Capture schema in a local constant so it’s safe inside the escaping closure
        let schema = defaultUserSchema
        
        userRef.getDocument { document, error in
            guard let document = document, document.exists else {
                print("⚠️ User document not found.")
                return
            }
            
            var updates: [String: Any] = [:]
            
            for (key, defaultValue) in schema {
                if document.get(key) == nil {
                    updates[key] = defaultValue
                }
            }
            
            if !updates.isEmpty {
                userRef.updateData(updates) { error in
                    if let error = error {
                        print("❌ Failed to update missing fields:", error.localizedDescription)
                    } else {
                        print("✅ Synced missing fields for user:", userID)
                    }
                }
            } else {
                print("✅ All fields already exist for user:", userID)
            }
        }
    }
    
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            self.isAuthenticated = false
            
            NotificationCenter.default.post(name: .didLogout, object: nil)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func deleteUserAccount() async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "DeleteAccount", code: 0, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        let db = Firestore.firestore()
        
        // 1️⃣ Delete user document
        try await db.collection("users").document(uid).delete()
        
        // 2️⃣ Remove user from chats & optionally delete their messages
        let chatsQuery = try await db.collection("chats")
            .whereField("participants", arrayContains: uid)
            .getDocuments()
        
        for chatDoc in chatsQuery.documents {
            let chatRef = chatDoc.reference
            
            // Delete user's messages in this chat
            let messagesSnapshot = try await chatRef.collection("messages").getDocuments()
            for messageDoc in messagesSnapshot.documents {
                if messageDoc.data()["senderId"] as? String == uid {
                    try await messageDoc.reference.delete()
                }
            }
            
            // Remove user from participants array
            try await chatRef.updateData([
                "participants": FieldValue.arrayRemove([uid])
            ])
        }
        
        // 3️⃣ Delete Firebase Auth account
        try await Auth.auth().currentUser?.delete()
    }
    
    func resetFields() {
        email = ""
        password = ""
        username = ""
        otpCode = ""
        phoneNumber = ""
        errorMessage = nil
        // If you added confirmPassword in Signup, reset it too
        confirmPassword = ""
    }
}

extension Notification.Name {
    static let didLogout = Notification.Name("didLogout")
    static let profileTabDidDisappear = Notification.Name("profileTabDidDisappear")
}
