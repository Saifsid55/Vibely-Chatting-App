//
//  ChatDetailViewModel.swift
//  Vibely
//
//  Created by Mohd Saif on 17/09/25.
//
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
    
    let chat: Chat
    private let db = Firestore.firestore()          // ✅ Added Firestore reference
    private var listener: ListenerRegistration?     // ✅ To keep real-time updates
    
    init(chat: Chat) {
        self.chat = chat
        startListening()                            // ✅ Start Firestore listener instead of dummy load
    }
    
    deinit {
        listener?.remove()                          // ✅ Clean up listener when ViewModel deallocates
    }
    
    // MARK: - Chat Info for View
    var chatName: String { chat.name }
    var chatInitial: String { String(chat.name.prefix(1)) }
    
    // MARK: - Real-time listener (was loadMessages)
    private func startListening() {
        isLoading = true
        
        listener = db.collection("chats")
            .document(chat.id ?? "")                      // ✅ Each chat has a unique document id
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
                    try? doc.data(as: Message.self) // ✅ Firestore decoding (Message must be Codable)
                } ?? []
            }
    }
    
    // MARK: - Send message (now pushes to Firestore)
    func sendMessage() {
        guard !newMessage.isEmpty,
              let uid = Auth.auth().currentUser?.uid,
              let chatId = chat.id else { return }
        
        let text = newMessage   // ✅ capture value safely outside
        let messageId = UUID().uuidString
        let now = Timestamp(date: Date())
        
        let messageData: [String: Any] = [
            "senderId": uid,
            "text": text,
            "timestamp": now,
            "type": "text"
        ]
        
        let chatRef = db.collection("chats").document(chatId)
        
        // 1️⃣ Add the new message
        chatRef.collection("messages").document(messageId).setData(messageData) { error in
            if let error = error {
                print("❌ Error sending message: \(error.localizedDescription)")
                return
            }
            
            // 2️⃣ Update lastMessage + updatedAt
            chatRef.setData([
                "lastMessage": [
                    "senderId": uid,
                    "text": text,     // ✅ use local captured constant
                    "timestamp": now
                ],
                "updatedAt": now
            ], merge: true)
        }
        
        newMessage = ""  // ✅ clear input safely
    }
}
