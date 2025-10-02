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
