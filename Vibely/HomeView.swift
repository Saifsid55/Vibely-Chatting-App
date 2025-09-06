//
//  ContentView.swift
//  Vibely
//
//  Created by Mohd Saif on 06/09/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .white, location: 0.0),   // Start: white
                        .init(color: .white, location: 0.8),   // Still white until 80%
                        .init(color: Color.blue.opacity(0.4),  location: 1.0)    // Smoothly fades to blue at bottom
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                VStack {
                    // Search Bar
                    TextField("Search users...", text: $viewModel.searchText)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                        .padding(.horizontal)
                    
                    ChatList(chats: viewModel.filteredChats, formatDate: viewModel.formatDate)
                }
                .navigationTitle("Chats")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            // Open Settings/Profile screen
                        }) {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                // Floating Action Button
                .overlay(
                    Button(action: {
                        // Start new chat
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24))
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                        .padding(),
                    alignment: .bottomTrailing
                )
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
                .overlay(Text(chat.name.prefix(1)).foregroundColor(.white))
            
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
    
    var body: some View {
        List(chats) { chat in
            NavigationLink(destination: ChatDetailView(chat: chat)) {
                ChatRow(chat: chat, formattedDate: formatDate(chat.timestamp))
            }
        }
        .listStyle(.plain)
    }
}


//#Preview {
//    HomeView()
//}
