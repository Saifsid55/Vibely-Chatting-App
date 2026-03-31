import Foundation
import FirebaseAuth

final class FirebaseAuthRepository: AuthRepository {
    func currentUserID() -> String? {
        Auth.auth().currentUser?.uid
    }

    func signUp(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user.uid
    }

    func signIn(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user.uid
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func deleteCurrentUser() async throws {
        try await Auth.auth().currentUser?.delete()
    }

    func sendOTP(to phoneNumber: String) async throws -> String {
        let formattedPhone = "+91" + phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !phoneNumber.isEmpty else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Phone number cannot be empty"])
        }

        return try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(formattedPhone, uiDelegate: nil) { verificationID, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let verificationID else {
                    continuation.resume(throwing: NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get verification ID"]))
                    return
                }

                continuation.resume(returning: verificationID)
            }
        }
    }

    func verifyOTP(verificationID: String, code: String) async throws {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        _ = try await Auth.auth().signIn(with: credential)
    }
}
