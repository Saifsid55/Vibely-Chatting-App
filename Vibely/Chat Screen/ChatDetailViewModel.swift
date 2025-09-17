//
//  ChatDetailViewModel.swift
//  Vibely
//
//  Created by Mohd Saif on 17/09/25.
//

import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var newMessage: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    
    private let chat: Chat
    
    init(chat: Chat) {
        self.chat = chat
        loadMessages()
    }
    
    // MARK: - Chat Info for View
    var chatName: String { chat.name }
    var chatInitial: String { String(chat.name.prefix(1)) }
    
    // MARK: - Load dummy messages (later from Firebase)
    func loadMessages() {
        isLoading = true
        // For now, just mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.messages = [
                Message(text: "Hey there!", sender: .other, timestamp: Date(), type: .text),
                Message(text: "Hi! How are you?", sender: .me, timestamp: Date(), type: .text)
            ]
            self.isLoading = false
        }
    }
    
    // MARK: - Send message
    func sendMessage() {
        guard !newMessage.isEmpty else { return }
        
        let message = Message(
            text: newMessage,
            sender: .me,
            timestamp: Date(),
            type: .text
        )
        
        messages.append(message)
        newMessage = ""
        
        // 🔜 Later: push to Firebase
    }
}

