import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
final class HomeViewModel: HomeViewModelProtocol {
    @Published var chats: [Chat] = []
    @Published var searchText = ""
    @Published var searchResults: [AppUserModel] = []
    @Published var allUsersDict: [String: AppUserModel] = [:]
    @Published var selectedChat: Chat?
    @Published var isUserAuthenticated = false

    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private var listener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    private let chatRepository: ChatRepository
    private let homeUseCases: HomeUseCases

    init(chatRepository: ChatRepository) {
        self.chatRepository = chatRepository
        self.homeUseCases = HomeUseCases(chatRepository: chatRepository)
        observeAuthState()
        bindSearch()
    }

    convenience init() {
        self.init(chatRepository: FirebaseChatRepository(db: Firestore.firestore()))
    }

    private func bindSearch() {
        $searchText
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task { await self?.searchUsers(query: query) }
            }
            .store(in: &cancellables)
    }

    func listenToChats() async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        listener?.remove()
        listener = chatRepository.listenToChats(for: currentUid) { [weak self] chats in
            self?.chats = chats
        } onError: { error in
            print("❌ Error fetching chats: \(error.localizedDescription)")
        }
    }

    func loadAllUsers() async {
        do {
            allUsersDict = try await homeUseCases.loadAllUsersDict()
        } catch {
            print("❌ Failed to load users: \(error.localizedDescription)")
        }
    }

    func searchUsers(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        do {
            var results = try await homeUseCases.searchUsers(query: query)
            if let currentUid = Auth.auth().currentUser?.uid {
                results.removeAll { $0.id == currentUid }
            }
            searchResults = results
        } catch {
            print("❌ Error searching users: \(error.localizedDescription)")
            searchResults = []
        }
    }

    func createOrFetchChat(with user: AppUserModel) async throws -> Chat {
        guard let currentUid = Auth.auth().currentUser?.uid,
              let otherUid = user.id else {
            throw NSError(domain: "NoUser", code: 401)
        }

        if let existingChat = try await chatRepository.fetchExistingChat(with: currentUid, otherUid: otherUid) {
            return existingChat
        }

        let avatarDict: [String: String] = [
            currentUid: allUsersDict[currentUid]?.avatarURL ?? "",
            otherUid: user.avatarURL ?? ""
        ]

        return Chat(id: nil, participants: [currentUid, otherUid], avatarURL: avatarDict, lastMessage: nil)
    }

    var filteredChats: [Chat] {
        guard !searchText.isEmpty else { return chats }
        return chats.filter { chat in
            let currentUid = Auth.auth().currentUser?.uid ?? ""
            let name = chat.displayName(for: currentUid, allUsers: allUsersDict)
            return name.lowercased().contains(searchText.lowercased())
        }
    }

    func deleteChat(_ chat: Chat, deleteFromBackend: Bool = true) async {
        guard let chatId = chat.id else { return }

        if deleteFromBackend {
            do {
                try await chatRepository.deleteChat(chatId: chatId)
                print("✅ Chat deleted from backend")
            } catch {
                print("❌ Error deleting chat: \(error.localizedDescription)")
            }
        }

        chats.removeAll { $0.id == chatId }
    }

    func selectUser(_ user: AppUserModel) async {
        do {
            selectedChat = try await createOrFetchChat(with: user)
        } catch {
            print("❌ \(error.localizedDescription)")
        }
    }

    func observeAuthState() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.isUserAuthenticated = (user != nil)
            if user != nil {
                Task { await self.listenToChats() }
            }
        }
    }

    deinit {
        listener?.remove()
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
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
