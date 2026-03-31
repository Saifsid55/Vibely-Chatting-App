import Foundation

protocol AuthRepository {
    func currentUserID() -> String?
    func signUp(email: String, password: String) async throws -> String
    func signIn(email: String, password: String) async throws -> String
    func signOut() throws
    func deleteCurrentUser() async throws
    func sendOTP(to phoneNumber: String) async throws -> String
    func verifyOTP(verificationID: String, code: String) async throws
}
