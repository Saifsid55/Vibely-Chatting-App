import Foundation
import FirebaseFirestore

final class FirebaseUserProfileRepository: UserProfileRepository {
    private let db: Firestore

    init(db: Firestore) {
        self.db = db
    }

    func fetchUser(uid: String) async throws -> AppUserModel? {
        let doc = try await db.collection("users").document(uid).getDocument()
        return try? doc.data(as: AppUserModel.self)
    }

    func saveUser(_ user: AppUserModel, uid: String) async throws {
        try db.collection("users").document(uid).setData(from: user)
    }

    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let snapshot = try await db.collection("users")
            .whereField("username", isEqualTo: username)
            .getDocuments()
        return snapshot.documents.isEmpty
    }

    func updateUsernameLowercase(uid: String, username: String) async throws {
        try await db.collection("users").document(uid).updateData([
            "username_lowercase": username.lowercased()
        ])
    }

    func syncUserSchema(uid: String, schema: [String: Any]) async {
        let userRef = db.collection("users").document(uid)

        do {
            let document = try await userRef.getDocument()
            guard document.exists else { return }

            var updates: [String: Any] = [:]
            for (key, defaultValue) in schema where document.get(key) == nil {
                updates[key] = defaultValue
            }

            if !updates.isEmpty {
                try await userRef.updateData(updates)
            }
        } catch {
            print("❌ Failed to sync schema: \(error.localizedDescription)")
        }
    }

    func deleteUserDocument(uid: String) async throws {
        try await db.collection("users").document(uid).delete()
    }
}
