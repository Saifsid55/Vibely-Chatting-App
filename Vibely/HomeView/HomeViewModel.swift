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
    @Published var searchResults: [AppUserModel] = []

    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        listenToChats()
    }
    
    /// Listen for all chats where current user is a participant
    private func listenToChats() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        listener?.remove()
        
        listener = db.collection("chats")
            .whereField("participants", arrayContains: uid)
            .order(by: "lastMessage.timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching chats: \(error.localizedDescription)")
                    return
                }
                
                self.chats = snapshot?.documents.compactMap { doc in
                    // Decode with LastMessage manually
                    let data = doc.data()
                    let id = doc.documentID
                    let name = data["name"] as? String ?? "Unknown"
                    let avatarURL = data["avatarURL"] as? String
                    let participants = data["participants"] as? [String] ?? []
                    
                    var lastMsg: LastMessage? = nil
                    if let lm = data["lastMessage"] as? [String: Any],
                       let text = lm["text"] as? String,
                       let senderId = lm["senderId"] as? String,
                       let timestamp = lm["timestamp"] as? Timestamp {
                        lastMsg = LastMessage(text: text, senderId: senderId, timestamp: timestamp.dateValue())
                    }
                    
                    return Chat(id: id, name: name, participants: participants, avatarURL: avatarURL, lastMessage: lastMsg)
                } ?? []
            }
    }
    
    
    func searchUsers(query: String) async {
        guard !query.isEmpty else {
            self.searchResults = []
            return
        }
        
        do {
            let usernameQuery = db.collection("users")
                .whereField("username", isEqualTo: query)
            
            let phoneQuery = db.collection("users")
                .whereField("phoneNumber", isEqualTo: query)
            
            // Combine both queries
            let usernameSnapshot = try await usernameQuery.getDocuments()
            let phoneSnapshot = try await phoneQuery.getDocuments()
            
            var results: [AppUserModel] = []
            results += usernameSnapshot.documents.compactMap { try? $0.data(as: AppUserModel.self) }
            results += phoneSnapshot.documents.compactMap { try? $0.data(as: AppUserModel.self) }
            
            // Remove duplicates
            self.searchResults = Array(Set(results))
        } catch {
            print("❌ Error searching users: \(error.localizedDescription)")
            self.searchResults = []
        }
    }
    
    var filteredChats: [Chat] {
        if searchText.isEmpty { return chats }
        return chats.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    deinit {
        listener?.remove()
    }
}
