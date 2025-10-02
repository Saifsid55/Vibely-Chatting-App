//
//  ContentView.swift
//  Vibely
//
//  Created by Mohd Saif on 06/09/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var path: [Route] = []  // navigation path
    
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
                    // Search Bar
                    TextField("Search users...", text: $viewModel.searchText)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                        .padding(.horizontal)
                    
                    ChatList(chats: viewModel.filteredChats,
                             formatDate: viewModel.formatDate,
                             path: $path)
                }
                .navigationTitle("Chats")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            path.append(.profile)
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                // Floating Action Button
                .overlay(alignment: .bottomTrailing) {
                    Button(action: {
                        // TODO: Open "new chat" flow
                    }) {
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
            // Navigation destinations
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .chat(let chat):
                    ChatDetailView(chat: chat)
                case .profile:
                    ProfileView()
                }
            }
        }
    }
}

struct ChatRow: View {
    let chat: Chat
    let formattedDate: String
    
    var body: some View {
        HStack {
            // Avatar
            if let avatar = chat.avatarURL, !avatar.isEmpty {
                AsyncImage(url: URL(string: avatar)) { image in
                    image.resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(chat.name.prefix(1))
                            .foregroundColor(.white)
                    }
            }
            
            // Chat info
            VStack(alignment: .leading, spacing: 2) {
                Text(chat.name).font(.headline)
                Text(chat.lastMessage?.text ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Last message time
            if let timestamp = chat.lastMessage?.timestamp {
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct ChatList: View {
    let chats: [Chat]
    let formatDate: (Date) -> String
    @Binding var path: [Route]
    
    var body: some View {
        List(chats) { chat in
            NavigationLink(value: Route.chat(chat)) {
                ChatRow(chat: chat,
                        formattedDate: chat.lastMessage.map { formatDate($0.timestamp) } ?? "")
            }
        }
        .listStyle(.plain)
    }
}


//#Preview {
//    HomeView()
//}
