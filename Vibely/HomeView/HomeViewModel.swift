//
//  HomeViewModel.swift
//  Vibely
//
//  Created by Mohd Saif on 06/09/25.
//

import Foundation

final class HomeViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var searchText: String = ""
    
    init() {
        loadChats()
    }
    
    private func loadChats() {
        // Mock data (replace with API/database later)
        chats = [
            Chat(id: UUID(), name: "Alice", lastMessage: "See you tomorrow!", timestamp: Date(), avatarURL: nil),
            Chat(id: UUID(), name: "Ali", lastMessage: "Assalamu Alaikum 👋🏻", timestamp: Date(), avatarURL: nil),
            Chat(id: UUID(), name: "Bob", lastMessage: "Got it, thanks!", timestamp: Date().addingTimeInterval(-3600), avatarURL: nil),
            Chat(id: UUID(), name: "Kaif", lastMessage: "Paisa dede malik!", timestamp: Date().addingTimeInterval(-356600), avatarURL: nil)
        ]
    }
    
    var filteredChats: [Chat] {
        if searchText.isEmpty {
            return chats
        }
        return chats.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
