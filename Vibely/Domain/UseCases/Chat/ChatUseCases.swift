import Foundation
import FirebaseFirestore

struct ChatUseCases {
    let chatRepository: ChatRepository

    func createMessage(
        chatId: String,
        messageId: String,
        senderId: String,
        text: String,
        timestamp: Timestamp
    ) async throws {
        try await chatRepository.sendMessage(
            chatId: chatId,
            messageId: messageId,
            senderId: senderId,
            text: text,
            timestamp: timestamp
        )
    }
}
