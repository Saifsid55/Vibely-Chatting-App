import Foundation
import FirebaseFirestore

final class FirebaseChatRepository: ChatRepository {
    private let db: Firestore

    init(db: Firestore) {
        self.db = db
    }

    @discardableResult
    func listenToChats(
        for uid: String,
        onChange: @escaping ([Chat]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {
        db.collection("chats")
            .whereField("participants", arrayContains: uid)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onError(error)
                    return
                }

                let fetchedChats = snapshot?.documents.compactMap { doc -> Chat? in
                    let data = doc.data()
                    let participants = Array(Set(data["participants"] as? [String] ?? []))
                    let avatarData = data["avatarURL"] as? [String: String]

                    var lastMsg: LastMessage?
                    if let lm = data["lastMessage"] as? [String: Any],
                       let text = lm["text"] as? String,
                       let senderId = lm["senderId"] as? String,
                       let timestamp = lm["timestamp"] as? Timestamp {
                        lastMsg = LastMessage(text: text, senderId: senderId, timestamp: timestamp.dateValue())
                    }
                    return Chat(id: doc.documentID, participants: participants, avatarURL: avatarData, lastMessage: lastMsg)
                } ?? []

                let sortedChats = fetchedChats.sorted { c1, c2 in
                    let t1 = c1.lastMessage?.timestamp ?? Date.distantPast
                    let t2 = c2.lastMessage?.timestamp ?? Date.distantPast
                    return t1 > t2
                }

                onChange(sortedChats)
            }
    }

    @discardableResult
    func listenToMessages(
        chatId: String,
        onChange: @escaping (QuerySnapshot) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {
        db.collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onError(error)
                    return
                }
                if let snapshot {
                    onChange(snapshot)
                }
            }
    }

    func fetchAllUsers() async throws -> [AppUserModel] {
        let snapshot = try await db.collection("users").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: AppUserModel.self) }
    }

    func searchUsers(exactUsername: String, phone: String) async throws -> [AppUserModel] {
        async let usernameSnapshot = db.collection("users")
            .whereField("username_lowercase", isEqualTo: exactUsername)
            .getDocuments()

        async let phoneSnapshot = db.collection("users")
            .whereField("phoneNumber", isEqualTo: phone)
            .getDocuments()

        let usernameDocs = try await usernameSnapshot
        let phoneDocs = try await phoneSnapshot

        var results: [AppUserModel] = []
        results += usernameDocs.documents.compactMap { try? $0.data(as: AppUserModel.self) }
        results += phoneDocs.documents.compactMap { try? $0.data(as: AppUserModel.self) }
        return Array(Set(results))
    }

    func fetchExistingChat(with currentUid: String, otherUid: String) async throws -> Chat? {
        let querySnapshot = try await db.collection("chats")
            .whereField("participants", arrayContains: currentUid)
            .getDocuments()

        guard let existingDoc = querySnapshot.documents.first(where: { doc in
            let participants = doc["participants"] as? [String] ?? []
            return participants.contains(otherUid)
        }) else { return nil }

        let data = existingDoc.data()
        let participants = Array(Set(data["participants"] as? [String] ?? []))
        let avatarData = data["avatarURL"] as? [String: String]

        var lastMsg: LastMessage?
        if let lm = data["lastMessage"] as? [String: Any],
           let text = lm["text"] as? String,
           let senderId = lm["senderId"] as? String,
           let timestamp = lm["timestamp"] as? Timestamp {
            lastMsg = LastMessage(text: text, senderId: senderId, timestamp: timestamp.dateValue())
        }

        return Chat(id: existingDoc.documentID, participants: participants, avatarURL: avatarData, lastMessage: lastMsg)
    }

    func createChat(participants: [String], avatarURL: [String: String], senderId: String, text: String, timestamp: Timestamp) async throws -> String {
        let chatRef = db.collection("chats").document()
        try await chatRef.setData([
            "participants": participants,
            "avatarURL": avatarURL,
            "lastMessage": [
                "senderId": senderId,
                "text": text,
                "timestamp": timestamp
            ],
            "updatedAt": timestamp
        ])
        return chatRef.documentID
    }

    func sendMessage(chatId: String, messageId: String, senderId: String, text: String, timestamp: Timestamp) async throws {
        try await db.collection("chats")
            .document(chatId)
            .collection("messages")
            .document(messageId)
            .setData([
                "senderId": senderId,
                "text": text,
                "timestamp": timestamp,
                "type": "text",
                "status": MessageStatus.sent.rawValue
            ])

        try await db.collection("chats")
            .document(chatId)
            .setData([
                "lastMessage": [
                    "senderId": senderId,
                    "text": text,
                    "timestamp": timestamp
                ],
                "updatedAt": timestamp
            ], merge: true)
    }

    func updateMessageStatus(chatId: String, messageId: String, status: MessageStatus) async {
        try? await db.collection("chats")
            .document(chatId)
            .collection("messages")
            .document(messageId)
            .updateData(["status": status.rawValue])
    }

    func deleteChat(chatId: String) async throws {
        try await db.collection("chats").document(chatId).delete()
    }
}
