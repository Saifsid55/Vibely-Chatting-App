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
    @Published var allUsersDict: [String: AppUserModel] = [:]
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() { }
    
    // MARK: - Listen for chats where current user is a participant
    func listenToChats() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        listener?.remove()
        
        listener = db.collection("chats")
            .whereField("participants", arrayContains: currentUid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching chats: \(error.localizedDescription)")
                    return
                }
                
                let fetchedChats: [Chat] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    let id = doc.documentID
                    let participants = Array(Set(data["participants"] as? [String] ?? []))
                    
                    // Avatar dictionary per participant
                    let avatarData = data["avatarURL"] as? [String: String]
                    
                    // Last message
                    var lastMsg: LastMessage? = nil
                    if let lm = data["lastMessage"] as? [String: Any],
                       let text = lm["text"] as? String,
                       let senderId = lm["senderId"] as? String,
                       let timestamp = lm["timestamp"] as? Timestamp {
                        lastMsg = LastMessage(text: text, senderId: senderId, timestamp: timestamp.dateValue())
                    }
                    
                    return Chat(id: id, participants: participants, avatarURL: avatarData, lastMessage: lastMsg)
                } ?? []
                
                // Sort by last message timestamp
                self.chats = fetchedChats.sorted { c1, c2 in
                    let t1 = c1.lastMessage?.timestamp ?? Date.distantPast
                    let t2 = c2.lastMessage?.timestamp ?? Date.distantPast
                    return t1 > t2
                }
            }
    }
    
    // MARK: - Load all users for dynamic chat names
    func loadAllUsers() async {
        do {
            let snapshot = try await db.collection("users").getDocuments()
            let users = snapshot.documents.compactMap { try? $0.data(as: AppUserModel.self) }
            allUsersDict = Dictionary(uniqueKeysWithValues: users.compactMap { user in
                guard let uid = user.id else { return nil }
                return (uid, user)
            })
        } catch {
            print("❌ Failed to load users: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Search Users
    func searchUsers(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
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
            
            if let currentUid = Auth.auth().currentUser?.uid {
                results.removeAll { $0.id == currentUid }
            }
            
            self.searchResults = Array(Set(results))
        } catch {
            print("❌ Error searching users: \(error.localizedDescription)")
            self.searchResults = []
        }
    }
    
    // MARK: - Create or fetch chat with another user
    func createOrFetchChat(with user: AppUserModel) async throws -> Chat {
        guard let currentUid = Auth.auth().currentUser?.uid,
              let otherUid = user.id else { throw NSError(domain: "NoUser", code: 401) }
        
        // 1️⃣ Look for existing chat
        let querySnapshot = try await db.collection("chats")
            .whereField("participants", arrayContains: currentUid)
            .getDocuments()
        
        if let existingDoc = querySnapshot.documents.first(where: { doc in
            let participants = doc["participants"] as? [String] ?? []
            return participants.contains(otherUid)
        }) {
            let data = existingDoc.data()
            let id = existingDoc.documentID
            let participants = Array(Set(data["participants"] as? [String] ?? []))
            let avatarData = data["avatarURL"] as? [String: String]
            
            var lastMsg: LastMessage? = nil
            if let lm = data["lastMessage"] as? [String: Any],
               let text = lm["text"] as? String,
               let senderId = lm["senderId"] as? String,
               let timestamp = lm["timestamp"] as? Timestamp {
                lastMsg = LastMessage(text: text, senderId: senderId, timestamp: timestamp.dateValue())
            }
            
            return Chat(id: id, participants: participants, avatarURL: avatarData, lastMessage: lastMsg)
        }
        
        // 2️⃣ Create temporary chat (first message will save it to Firestore)
        let avatarDict: [String: String] = [
            currentUid: allUsersDict[currentUid]?.avatarURL ?? "",
            otherUid: user.avatarURL ?? ""
        ]
        
        return Chat(id: nil, participants: [currentUid, otherUid], avatarURL: avatarDict, lastMessage: nil)
    }
    
    // MARK: - Filtered chats
    var filteredChats: [Chat] {
        if searchText.isEmpty { return chats }
        return chats.filter { chat in
            let currentUid = Auth.auth().currentUser?.uid ?? ""
            let name = chat.displayName(for: currentUid, allUsers: allUsersDict)
            return name.lowercased().contains(searchText.lowercased())
        }
    }
    
    // MARK: - Format date
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let now = Date()
        
        // Calculate time difference in hours
        let hoursPassed = now.timeIntervalSince(date) / 3600
        
        if hoursPassed < 24 {
            // Within 24 hours → show only time
            formatter.timeStyle = .short
            formatter.dateStyle = .none
        } else {
            // More than 24 hours → show date + time
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
        }
        
        return formatter.string(from: date)
    }
    
    // MARK: - Delete chat
    func deleteChat(_ chat: Chat, deleteFromBackend: Bool = true) async {
        guard let chatId = chat.id else { return }
        
        if deleteFromBackend {
            do {
                try await db.collection("chats").document(chatId).delete()
                print("✅ Chat deleted from backend")
            } catch {
                print("❌ Error deleting chat: \(error.localizedDescription)")
            }
        }
        
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats.remove(at: index)
        }
    }
    
    deinit {
        listener?.remove()
    }
}


extension HomeViewModel {
    
    func chatDisplayName(_ chat: Chat) -> String {
        guard let currentUid = Auth.auth().currentUser?.uid else { return "Unknown" }
        let otherUid = chat.participants.first { $0 != currentUid } ?? chat.participants.first ?? ""
        return allUsersDict[otherUid]?.username ?? "Unknown"
    }
    
    func chatDisplayAvatar(_ chat: Chat) -> String? {
        guard let currentUid = Auth.auth().currentUser?.uid else { return nil }
        let otherUid = chat.participants.first { $0 != currentUid } ?? chat.participants.first ?? ""
        return allUsersDict[otherUid]?.avatarURL
    }
}
