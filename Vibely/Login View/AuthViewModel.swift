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
    
    @Published var verificationID: String?
    private let db = Firestore.firestore()
    
    var isPasswordMatching: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    init() {
        checkCurrentUser()
    }
    
    func checkCurrentUser() {
        if let user = Auth.auth().currentUser {
            // Load Firestore user
            
            Task {
                try await loadUser(uid: user.uid)
            }
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Helpers
    private func checkUserExistsOrNavigate(uid: String, email: String?, phone: String?) {
        Task {
            let doc = try? await db.collection("users").document(uid).getDocument()
            if let doc = doc, doc.exists {
                currentUser = try? doc.data(as: AppUserModel.self)
                isAuthenticated = true
            } else {
                // New user -> go to username screen
                showUsernameScreen = true
            }
        }
    }
    
    private func loadUser(uid: String) async throws {
        let doc = try await db.collection("users").document(uid).getDocument()
        if let user = try? doc.data(as: AppUserModel.self) {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            self.isAuthenticated = false
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
