//
//  ContentView.swift
//  Vibely
//
//  Created by Mohd Saif on 06/09/25.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var path: [Route] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .white, location: 0.0),
                        .init(color: .white, location: 0.8),
                        .init(color: Color.blue.opacity(0.4), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    TextField("Search users...", text: $viewModel.searchText)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                        .padding(.horizontal)
                        .onChange(of: viewModel.searchText) { oldValue, newValue in
                            Task {
                                await viewModel.searchUsers(query: newValue)
                            }
                        }
                    if !viewModel.searchResults.isEmpty {
                        List(viewModel.searchResults) { user in
                            Button {
                                // TODO: Start a chat with selected user
                                Task {
                                    do {
                                        let chat = try await viewModel.createOrFetchChat(with: user)
                                        path.append(.chat(chat)) // navigate to chat
                                        viewModel.searchText = ""  // optional: clear search
                                        viewModel.searchResults = []
                                    } catch {
                                        print("❌ Failed to create/fetch chat: \(error.localizedDescription)")
                                    }
                                }
                                
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 40, height: 40)
                                        .overlay(Text(user.username.prefix(1)).foregroundColor(.white))
                                    VStack(alignment: .leading) {
                                        Text(user.username).font(.headline)
                                        Text(user.phoneNumber ?? "").font(.subheadline).foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .frame(maxHeight: 200) // optional
                    }
                    
                    ChatList(chats: viewModel.filteredChats,
                             formatDate: viewModel.formatDate,
                             path: $path)
                    .environmentObject(viewModel)
                }
                
                .navigationTitle("Chats")
                .navigationBarTitleDisplayMode(.inline)  // ✅ Add this line
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            path.append(.profile)
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        // TODO: new chat flow
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24))
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .chat(let chat):
                    ChatDetailView(chat: chat, allUsers: viewModel.allUsersDict)
                case .profile:
                    ProfileView()
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadAllUsers()
                    if Auth.auth().currentUser != nil {
                        viewModel.listenToChats()
                    } else {
                        // Optionally, observe Auth state and start listening when user logs in
                        Auth.auth().addStateDidChangeListener { _, user in
                            if user != nil {
                                viewModel.listenToChats()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ChatList: View {
    let chats: [Chat]
    let formatDate: (Date) -> String
    @Binding var path: [Route]
    @State private var showDeleteConfirm = false
    @State private var chatToDelete: Chat? = nil
    @EnvironmentObject var homeVM: HomeViewModel
    
    var body: some View {
        List(chats) { chat in
            NavigationLink(value: Route.chat(chat)) {
                ChatRow(chat: chat,
                        formattedDate: chat.lastMessage.map { formatDate($0.timestamp) } ?? "")
            }
            .contextMenu {
                Button(role: .destructive) {
                    chatToDelete = chat
                    showDeleteConfirm = true
                } label: {
                    Label("Delete Chat", systemImage: "trash")
                }
            }
        }
        .listStyle(.plain)
        .confirmationDialog("Delete this chat?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let chat = chatToDelete {
                    Task {
                        await homeVM.deleteChat(chat, deleteFromBackend: true)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}


struct ChatRow: View {
    let chat: Chat
    let formattedDate: String
    @EnvironmentObject var homeVM: HomeViewModel
    
    var body: some View {
        HStack {
            if let avatarURL = homeVM.chatDisplayAvatar(chat),
               let url = URL(string: avatarURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
                    .overlay(Text(homeVM.chatDisplayName(chat).prefix(1))
                        .foregroundColor(.white))
            }
            
            VStack(alignment: .leading) {
                Text(homeVM.chatDisplayName(chat))
                Text(chat.lastMessage?.text ?? "Say hello 👋")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            Text(formattedDate)
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
}


//#Preview {
//    HomeView()
//}
