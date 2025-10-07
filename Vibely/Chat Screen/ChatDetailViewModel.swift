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
    
    var chat: Chat
    private let db = Firestore.firestore()          // ✅ Added Firestore reference
    private var listener: ListenerRegistration?     // ✅ To keep real-time updates
    
    init(chat: Chat) {
        self.chat = chat
        
        // Only start listener if chat exists in Firestore
        if let chatId = chat.id {
            startListening(chatId: chatId)
        } else {
            messages = [] // temporary chat, no Firestore yet
        }
        // ✅ Start Firestore listener instead of dummy load
    }
    
    deinit {
        listener?.remove()                          // ✅ Clean up listener when ViewModel deallocates
    }
    
    // MARK: - Chat Info for View
    var chatName: String { chat.name }
    var chatInitial: String { String(chat.name.prefix(1)) }
    
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
                
                self.messages = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Message.self)
                } ?? []
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
                    "name": chat.name,
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
                "type": "text"
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
}







/*
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
    
    @Published var chat: Chat
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init(chat: Chat) {
        self.chat = chat
        if chat.id != nil && !chat.id!.isEmpty {
            startListening()
        } else {
            print("⚠️ Chat doesn't exist in Firestore yet. Will create on first message.")
        }
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Chat Info for View
    var chatName: String { chat.name }
    var chatInitial: String { String(chat.name.prefix(1)) }
    
    // MARK: - Real-time listener
    private func startListening() {
        guard let chatId = chat.id, !chatId.isEmpty else {
            print("⚠️ Cannot start listening: chat.id is nil or empty")
            return
        }
        
        isLoading = true
        
        listener = db.collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                Task { @MainActor in
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        print("❌ Listener error: \(error.localizedDescription)")
                        return
                    }
                    
                    self.messages = snapshot?.documents.compactMap { doc in
                        try? doc.data(as: Message.self)
                    } ?? []
                }
            }
    }
    
    // MARK: - Send message
    func sendMessage() {
        guard !newMessage.isEmpty,
              let uid = Auth.auth().currentUser?.uid else {
            print("⚠️ Cannot send message: empty message or no user")
            return
        }
        
        let text = newMessage
        newMessage = ""  // ✅ Clear immediately for better UX
        
        let messageId = UUID().uuidString
        let now = Timestamp(date: Date())
        
        let messageData: [String: Any] = [
            "senderId": uid,
            "text": text,
            "timestamp": now,
            "type": "text"
        ]
        
        // ✅ Check if this is a new chat (no ID yet)
        if chat.id == nil || chat.id!.isEmpty {
            Task {
                await createChatAndSendFirstMessage(messageData: messageData, text: text, now: now, uid: uid, messageId: messageId)
            }
        } else {
            // ✅ Chat exists, just send the message
            Task {
                await sendMessageToExistingChat(chatId: chat.id!, messageData: messageData, text: text, now: now, uid: uid, messageId: messageId)
            }
        }
    }
    
    // ✅ Helper: Create new chat document and send first message
    private func createChatAndSendFirstMessage(messageData: [String: Any], text: String, now: Timestamp, uid: String, messageId: String) async {
        let newChatId = UUID().uuidString
        let chatRef = db.collection("chats").document(newChatId)
        
        print("🆕 Creating new chat: \(newChatId)")
        
        // Capture values that need to be accessed
        let chatName = chat.name
        let chatParticipants = chat.participants
        let chatAvatarURL = chat.avatarURL
        
        // Create the chat document with all required fields
        let chatData: [String: Any] = [
            "name": chatName,
            "participants": chatParticipants,
            "avatarURL": chatAvatarURL as Any,
            "createdAt": now,
            "updatedAt": now,
            "lastMessage": [
                "senderId": uid,
                "text": text,
                "timestamp": now
            ]
        ]
        
        do {
            // 1️⃣ Create the chat document
            try await chatRef.setData(chatData)
            print("✅ Chat document created: \(newChatId)")
            
            // 2️⃣ Update local chat object with the new ID
            self.chat.id = newChatId
            
            // 3️⃣ Add the message to the subcollection
            try await chatRef.collection("messages").document(messageId).setData(messageData)
            print("✅ First message sent")
            
            // 4️⃣ Start listening for future messages
            self.startListening()
            
        } catch {
            print("❌ Error creating chat or sending message: \(error.localizedDescription)")
            self.errorMessage = "Failed to create chat"
        }
    }
    
    // ✅ Helper: Send message to existing chat
    private func sendMessageToExistingChat(chatId: String, messageData: [String: Any], text: String, now: Timestamp, uid: String, messageId: String) async {
        let chatRef = db.collection("chats").document(chatId)
        
        do {
            // 1️⃣ Add the message
            try await chatRef.collection("messages").document(messageId).setData(messageData)
            
            // 2️⃣ Update lastMessage and updatedAt
            try await chatRef.setData([
                "lastMessage": [
                    "senderId": uid,
                    "text": text,
                    "timestamp": now
                ],
                "updatedAt": now
            ], merge: true)
            
        } catch {
            print("❌ Error sending message: \(error.localizedDescription)")
        }
    }
}
*/
