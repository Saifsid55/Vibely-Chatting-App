import Foundation

struct HomeUseCases {
    let chatRepository: ChatRepository

    func loadAllUsersDict() async throws -> [String: AppUserModel] {
        let users = try await chatRepository.fetchAllUsers()
        return Dictionary(uniqueKeysWithValues: users.compactMap { user in
            guard let uid = user.id else { return nil }
            return (uid, user)
        })
    }

    func searchUsers(query: String) async throws -> [AppUserModel] {
        let lowercasedQuery = query.lowercased()
        return try await chatRepository.searchUsers(exactUsername: lowercasedQuery, phone: query)
    }
}
