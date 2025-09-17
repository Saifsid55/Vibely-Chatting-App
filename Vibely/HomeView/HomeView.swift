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
                        Button(action: {
                            path.append(.profile)
                            // Open Settings/Profile screen
                        }) {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                // Floating Action Button
                .overlay(alignment: .bottomTrailing) {
                    Button(action: {
                        // Start new chat
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
            // Define destination for Chat
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
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
                .overlay(alignment: .center) {
                    Text(chat.name.prefix(1))
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading) {
                Text(chat.name).font(.headline)
                Text(chat.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.gray)
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
                ChatRow(chat: chat, formattedDate: formatDate(chat.timestamp))
            }
        }
        .listStyle(.plain)
    }
}


//#Preview {
//    HomeView()
//}
