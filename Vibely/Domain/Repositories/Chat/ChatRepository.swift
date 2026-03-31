import Foundation
import FirebaseFirestore

protocol ChatRepository {
    @discardableResult
    func listenToChats(for uid: String, onChange: @escaping ([Chat]) -> Void, onError: @escaping (Error) -> Void) -> ListenerRegistration
    @discardableResult
    func listenToMessages(chatId: String, onChange: @escaping (QuerySnapshot) -> Void, onError: @escaping (Error) -> Void) -> ListenerRegistration
    func fetchAllUsers() async throws -> [AppUserModel]
    func searchUsers(exactUsername: String, phone: String) async throws -> [AppUserModel]
    func fetchExistingChat(with currentUid: String, otherUid: String) async throws -> Chat?
    func createChat(participants: [String], avatarURL: [String: String], senderId: String, text: String, timestamp: Timestamp) async throws -> String
    func sendMessage(chatId: String, messageId: String, senderId: String, text: String, timestamp: Timestamp) async throws
    func updateMessageStatus(chatId: String, messageId: String, status: MessageStatus) async
    func deleteChat(chatId: String) async throws
}
