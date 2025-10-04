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
        // Remove auto call from init to prevent listener running before user logs in
    }
    
    // MARK: - Listen for all chats where current user is a participant
    func listenToChats() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        listener?.remove()
        
        // ✅ Try with backticks for nested field path
        listener = db.collection("chats")
            .whereField("participants", arrayContains: uid)
            .order(by: FieldPath(["lastMessage", "timestamp"]), descending: true)
//            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching chats: \(error.localizedDescription)")
                    if let snapshot = snapshot {
                        print("📄 Partial snapshot: \(snapshot.documents.map { $0.data() })")
                    }
                    return
                }
                
                print("🟢 Chats updated for user \(uid): \(snapshot?.documents.count ?? 0) chats found")
                
                let fetchedChats: [Chat] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    let id = doc.documentID
                    let name = data["name"] as? String ?? "Unknown"
                    let avatarURL = data["avatarURL"] as? String
                    
                    var participants = Array(Set(data["participants"] as? [String] ?? []))
                    if !participants.contains(uid) { participants.append(uid) }
                    
                    var lastMsg: LastMessage? = nil
                    if let lm = data["lastMessage"] as? [String: Any],
                       let text = lm["text"] as? String,
                       let senderId = lm["senderId"] as? String,
                       let timestamp = lm["timestamp"] as? Timestamp {
                        lastMsg = LastMessage(text: text, senderId: senderId, timestamp: timestamp.dateValue())
                    }
                    
                    return Chat(id: id, name: name, participants: participants, avatarURL: avatarURL, lastMessage: lastMsg)
                } ?? []
                
                // ✅ Sort manually in-memory by lastMessage timestamp
                
                self.chats = fetchedChats.sorted { c1, c2 in
                    let t1 = c1.lastMessage?.timestamp ?? Date.distantPast
                    let t2 = c2.lastMessage?.timestamp ?? Date.distantPast
                    return t1 > t2
                }
            }
    }
    
    // MARK: - Search Users
    func searchUsers(query: String) async {
        guard !query.isEmpty else {
            self.searchResults = []
            return
        }
        
        do {
            let lowercasedQuery = query.lowercased()
            
            let usernameQuery = db.collection("users")
                .whereField("username_lowercase", isEqualTo: lowercasedQuery)
            
            let phoneQuery = db.collection("users")
                .whereField("phoneNumber", isEqualTo: query)
            
            let usernameSnapshot = try await usernameQuery.getDocuments()
            let phoneSnapshot = try await phoneQuery.getDocuments()
            
            var results: [AppUserModel] = []
            results += usernameSnapshot.documents.compactMap { try? $0.data(as: AppUserModel.self) }
            results += phoneSnapshot.documents.compactMap { try? $0.data(as: AppUserModel.self) }
            
            self.searchResults = Array(Set(results))
        } catch {
            print("❌ Error searching users: \(error.localizedDescription)")
            self.searchResults = []
        }
    }
    
    // MARK: - Create or fetch chat with user
    func createOrFetchChat(with user: AppUserModel) async throws -> Chat {
        guard
            let currentUid = Auth.auth().currentUser?.uid,
            let otherUid = user.id
        else { throw NSError(domain: "NoUser", code: 401) }
        
        // 1️⃣ Look for existing chat
        let querySnapshot = try await db.collection("chats")
            .whereField("participants", arrayContains: currentUid)
            .getDocuments()
        
        if let existing = querySnapshot.documents.first(where: { doc in
            let participants = doc["participants"] as? [String] ?? []
            return participants.contains(otherUid)
        }) {
            // Decode existing chat
            let data = existing.data()
            let id = existing.documentID
            let name = data["name"] as? String ?? "Unknown"
            let avatarURL = data["avatarURL"] as? String
            var participants = Array(Set(data["participants"] as? [String] ?? []))
            if !participants.contains(currentUid) { participants.append(currentUid) }
            if !participants.contains(otherUid) { participants.append(otherUid) }
            
            var lastMsg: LastMessage? = nil
            if let lm = data["lastMessage"] as? [String: Any],
               let text = lm["text"] as? String,
               let senderId = lm["senderId"] as? String,
               let timestamp = lm["timestamp"] as? Timestamp {
                lastMsg = LastMessage(text: text, senderId: senderId, timestamp: timestamp.dateValue())
            }
            
            return Chat(id: id, name: name, participants: participants, avatarURL: avatarURL, lastMessage: lastMsg)
        }
        
        // 2️⃣ Otherwise, create new chat
        let chatId = UUID().uuidString
        let newChat = Chat(
            id: chatId,
            name: user.username,
            participants: [currentUid, otherUid],
            avatarURL: user.avatarURL,
            lastMessage: LastMessage(text: "", senderId: "", timestamp: Date())
        )
        
        try await db.collection("chats").document(chatId).setData([
            "name": newChat.name,
            "participants": newChat.participants,
            "avatarURL": newChat.avatarURL as Any,
            "lastMessage": [
                "text": "",
                "senderId": "",
                "timestamp": Timestamp(date: Date())
            ],
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        chats.insert(newChat, at: 0)
        return newChat
    }
    
    // MARK: - Filtered Chats for UI
    var filteredChats: [Chat] {
        if searchText.isEmpty { return chats }
        return chats.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
    
    // MARK: - Format Date
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    deinit {
        listener?.remove()
    }
}
