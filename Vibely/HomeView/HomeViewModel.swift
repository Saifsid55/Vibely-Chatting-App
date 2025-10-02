//
//  HomeViewModel.swift
//  Vibely
//
//  Created by Mohd Saif on 06/09/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var searchText: String = ""
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        listenToChats()
    }
    
    /// Start listening to chats in Firestore
    private func listenToChats() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Stop old listener (to prevent duplicates)
        listener?.remove()
        
        listener = db.collection("chats")
            .whereField("participants", arrayContains: uid)   // only chats I belong to
            .order(by: "lastMessage.timestamp", descending: true) // newest chats first
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching chats: \(error.localizedDescription)")
                    return
                }
                
                self.chats = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Chat.self)   // ✅ Direct Codable decoding
                } ?? []
            }
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
    
    deinit {
        listener?.remove() // stop listening when viewModel deallocates
    }
}
