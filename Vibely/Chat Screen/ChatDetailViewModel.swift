import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class ChatViewModel: ChatViewModelProtocol {
    @Published var messages: [Message] = []
    @Published var newMessage = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var animatedMessageIDs: Set<String> = []
    @Published var userMood: String?

    private let allUsers: [String: AppUserModel]
    private let chatRepository: ChatRepository
    private let chatUseCases: ChatUseCases
    private var listener: ListenerRegistration?
    private let currentUid: String
    var chat: Chat

    init(
        chat: Chat,
        allUsers: [String: AppUserModel],
        chatRepository: ChatRepository = FirebaseChatRepository(db: Firestore.firestore())
    ) {
        self.chat = chat
        self.allUsers = allUsers
        self.chatRepository = chatRepository
        self.chatUseCases = ChatUseCases(chatRepository: chatRepository)
        self.currentUid = Auth.auth().currentUser?.uid ?? ""

        if let chatId = chat.id {
            startListening(chatId: chatId)
        }
    }

    deinit {
        listener?.remove()
    }

    var chatName: String {
        let otherUid = chat.participants.first { $0 != currentUid } ?? chat.participants.first ?? ""
        return allUsers[otherUid]?.username ?? "Unknown"
    }

    var chatInitial: String {
        String(chatName.prefix(1))
    }

    var chatAvatarURL: String? {
        let otherUid = chat.participants.first { $0 != currentUid } ?? chat.participants.first ?? ""
        return chat.avatarURL?[otherUid] ?? allUsers[otherUid]?.avatarURL
    }

    private func startListening(chatId: String) {
        isLoading = true
        listener = chatRepository.listenToMessages(chatId: chatId) { [weak self] snapshot in
            self?.handleMessagesSnapshot(snapshot)
        } onError: { [weak self] error in
            self?.errorMessage = error.localizedDescription
            self?.isLoading = false
        }
    }

    private func handleMessagesSnapshot(_ snapshot: QuerySnapshot) {
        isLoading = false

        var fetchedMessages: [Message] = []
        var newAnimatedIDs: Set<String> = []

        for change in snapshot.documentChanges {
            guard let message = try? change.document.data(as: Message.self) else { continue }
            fetchedMessages.append(message)

            if change.type == .modified, let id = message.id {
                newAnimatedIDs.insert(id)
            }
            if !message.isMe && message.status == .delivered {
                markMessagesAsSeen()
            } else if !message.isMe && message.status == .sent {
                markMessageAsDelivered(message)
            }
        }

        let existingMessages = messages.filter { msg in
            !fetchedMessages.contains(where: { $0.id == msg.id })
        }
        messages = (existingMessages + fetchedMessages).sorted { $0.timestamp < $1.timestamp }
        animatedMessageIDs.formUnion(newAnimatedIDs)

        if let lastReceivedMessage = messages.last(where: { !$0.isMe }) {
            detectMood(for: lastReceivedMessage.text ?? "")
        }
    }

    func sendMessage() {
        guard !newMessage.isEmpty,
              let uid = Auth.auth().currentUser?.uid else { return }

        let text = newMessage
        let now = Timestamp(date: Date())

        Task {
            do {
                if chat.id == nil {
                    let chatId = try await chatRepository.createChat(
                        participants: chat.participants,
                        avatarURL: chat.avatarURL ?? [:],
                        senderId: uid,
                        text: text,
                        timestamp: now
                    )
                    chat.id = chatId
                    startListening(chatId: chatId)
                }

                guard let chatId = chat.id else { return }
                try await chatUseCases.createMessage(
                    chatId: chatId,
                    messageId: UUID().uuidString,
                    senderId: uid,
                    text: text,
                    timestamp: now
                )
                newMessage = ""
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func markMessageAsDelivered(_ message: Message) {
        guard !message.isMe,
              let chatId = chat.id,
              let messageId = message.id else { return }

        Task {
            await chatRepository.updateMessageStatus(chatId: chatId, messageId: messageId, status: .delivered)
        }
    }

    func markMessagesAsSeen() {
        guard let chatId = chat.id else { return }

        for message in messages where !message.isMe && message.status != .seen {
            guard let messageId = message.id else { continue }
            Task {
                await chatRepository.updateMessageStatus(chatId: chatId, messageId: messageId, status: .seen)
            }
        }
    }

    func detectMood(for message: String) {
        MoodDetector.shared.detectMood(for: message) { [weak self] result in
            DispatchQueue.main.async {
                self?.userMood = result
            }
        }
    }
}
