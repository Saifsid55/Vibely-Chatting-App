import Foundation

protocol UserProfileRepository {
    func fetchUser(uid: String) async throws -> AppUserModel?
    func saveUser(_ user: AppUserModel, uid: String) async throws
    func isUsernameAvailable(_ username: String) async throws -> Bool
    func updateUsernameLowercase(uid: String, username: String) async throws
    func syncUserSchema(uid: String, schema: [String: Any]) async
    func deleteUserDocument(uid: String) async throws
}
