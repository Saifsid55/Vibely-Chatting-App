//
//  ChatDetailViewModel.swift
//  Vibely
//
//  Created by Mohd Saif on 17/09/25.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var newMessage: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var animatedMessageIDs: Set<String> = []
    
    private let allUsers: [String: AppUserModel]
    var chat: Chat
    private let db = Firestore.firestore()          // ✅ Added Firestore reference
    private var listener: ListenerRegistration?     // ✅ To keep real-time updates
    private let currentUid: String
    
    init(chat: Chat, allUsers: [String: AppUserModel]) {
        self.chat = chat
        self.allUsers = allUsers
        self.currentUid = Auth.auth().currentUser?.uid ?? ""
        
        // Only start listener if chat exists in Firestore
        if let chatId = chat.id {
            startListening(chatId: chatId)
        } else {
            messages = [] // temporary chat, no Firestore yet
        }
    }
    
    deinit {
        listener?.remove()                          // ✅ Clean up listener when ViewModel deallocates
    }
    
    // MARK: - Chat Info for View
    var chatName: String {
        // Use helper logic instead of chat.name
        let otherUid = chat.participants.first { $0 != currentUid } ?? chat.participants.first ?? ""
        return allUsers[otherUid]?.username ?? "Unknown"
    }
    
    var chatInitial: String {
        String(chatName.prefix(1))
    }
    
    var chatAvatarURL: String? {
        guard let currentUid = Auth.auth().currentUser?.uid else { return nil }
        let otherUid = chat.participants.first { $0 != currentUid } ?? chat.participants.first ?? ""
        return chat.avatarURL?[otherUid] ?? allUsers[otherUid]?.avatarURL
    }
    
    // MARK: - Real-time listener (was loadMessages)
    private func startListening(chatId: String) {
        isLoading = true
        listener = db.collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                let fetchedMessages: [Message] = snapshot?.documents.compactMap { doc in
                    
                    guard let message = try? doc.data(as: Message.self) else { return nil }
                    if !message.isMe && message.status == .delivered {
                        self.markMessagesAsSeen()
                    }
                    else if !message.isMe && message.status == .sent {
                        self.markMessageAsDelivered(message)
                    }
                    return message
                } ?? []
                
                if self.messages != fetchedMessages {
                    self.messages = fetchedMessages
                    // ✅ Mark seen only after new messages are fetched
//                    self.markMessagesAsSeen()
                }
            }
    }
    
    // MARK: - Send message
    func sendMessage() {
        guard !newMessage.isEmpty,
              let uid = Auth.auth().currentUser?.uid else { return }
        
        let text = newMessage
        let now = Timestamp(date: Date())
        
        Task {
            if chat.id == nil {
                // 1️⃣ Create new chat document in Firestore
                let chatRef = db.collection("chats").document()
                chat.id = chatRef.documentID
                
                let chatData: [String: Any] = [
                    "participants": chat.participants,
                    "avatarURL": chat.avatarURL ?? "",
                    "lastMessage": [
                        "senderId": uid,
                        "text": text,
                        "timestamp": now
                    ],
                    "updatedAt": now
                ]
                
                do {
                    try await chatRef.setData(chatData)
                    print("✅ Created new chat in Firestore")
                    
                    // Start listening now that chat exists
                    startListening(chatId: chat.id!)
                } catch {
                    print("❌ Failed to create chat: \(error)")
                    return
                }
            }
            
            // 2️⃣ Add message to messages collection
            guard let chatId = chat.id else { return }
            let messageId = UUID().uuidString
            let messageData: [String: Any] = [
                "senderId": uid,
                "text": text,
                "timestamp": now,
                "type": "text",
                "status": MessageStatus.sent.rawValue
            ]
            
            do {
                try await db.collection("chats")
                    .document(chatId)
                    .collection("messages")
                    .document(messageId)
                    .setData(messageData)
                
                // Update lastMessage
                try await db.collection("chats")
                    .document(chatId)
                    .setData([
                        "lastMessage": [
                            "senderId": uid,
                            "text": text,
                            "timestamp": now
                        ],
                        "updatedAt": now
                    ], merge: true)
                
                // Clear input
                await MainActor.run {
                    self.newMessage = ""
                }
                
            } catch {
                print("❌ Failed to send message: \(error)")
            }
        }
    }
    
    private func markMessageAsDelivered(_ message: Message) {
        guard !message.isMe, let chatId = chat.id, let messageId = message.id else { return }
        
        let messageRef = db.collection("chats")
            .document(chatId)
            .collection("messages")
            .document(messageId)
        
        messageRef.updateData(["status": MessageStatus.delivered.rawValue])
    }
    
    func markMessagesAsSeen() {
        guard let chatId = chat.id else { return }
        
        for message in messages where !message.isMe && message.status != .seen {
            db.collection("chats")
                .document(chatId)
                .collection("messages")
                .document(message.id!)
                .updateData(["status": MessageStatus.seen.rawValue])
        }
    }
}
