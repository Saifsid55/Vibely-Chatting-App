import Foundation
import SwiftUI

@MainActor
protocol AuthViewModelProtocol: ObservableObject {
    var email: String { get set }
    var password: String { get set }
    var username: String { get set }
    var currentUser: AppUserModel? { get }
    var isAuthenticated: Bool { get }
    var showUsernameScreen: Bool { get }
    var errorMessage: String? { get }
    var isLoading: Bool { get }

    func checkCurrentUser()
    func signupWithEmail() async throws
    func loginWithEmail() async
    func createUserProfile(uid: String, email: String?, phone: String?) async
    func signOut()
    func resetFields()
}

@MainActor
protocol HomeViewModelProtocol: ObservableObject {
    var chats: [Chat] { get }
    var searchText: String { get set }
    var searchResults: [AppUserModel] { get }
    var allUsersDict: [String: AppUserModel] { get }
    var selectedChat: Chat? { get set }

    func loadAllUsers() async
    func searchUsers(query: String) async
    func createOrFetchChat(with user: AppUserModel) async throws -> Chat
    func deleteChat(_ chat: Chat, deleteFromBackend: Bool) async
}

@MainActor
protocol ChatViewModelProtocol: ObservableObject {
    var messages: [Message] { get }
    var newMessage: String { get set }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var userMood: String? { get }

    func sendMessage()
    func markMessagesAsSeen()
}
