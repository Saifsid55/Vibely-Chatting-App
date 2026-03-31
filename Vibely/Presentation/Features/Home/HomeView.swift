//
//  ContentView.swift
//  Vibely
//
//  Created by Mohd Saif on 06/09/25.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @State private var path: [Route] = []
    @EnvironmentObject var router: Router
    @EnvironmentObject var tabRouter: TabRouter
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(hex: "#FFFFFF", location: 0.0),
                    .init(hex: "#FFFFFF", location: 0.7),
                    .init(hex: "#517fa4", location: 1.0),
                    //                            .init(hex: "#243949", location: 1.0)
                    
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
                if !viewModel.searchResults.isEmpty {
                    List(viewModel.searchResults) { user in
                        Button {
                            // TODO: Start a chat with selected user
                            Task {
                                do {
                                    let chat = try await viewModel.createOrFetchChat(with: user)
                                    router.goToChat(chat)// navigate to chat
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
                                    .overlay(Text(user.username.prefix(1)).foregroundStyle(.white))
                                VStack(alignment: .leading) {
                                    Text(user.username).font(.headline)
                                    Text(user.phoneNumber ?? "").font(.subheadline).foregroundStyle(.gray)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .frame(maxHeight: 200) // optional
                }
                
                ChatList(chats: viewModel.filteredChats,
                         path: $router.path)
                .environmentObject(viewModel)
                .environmentObject(router)
            }
            
            //                .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Color(hex: "#243949"))
            
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        router.goToProfile()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(
                                LinearGradient(hexColors: ["#243949", "#517fa4"],
                                               direction: .leftToRight))
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Text("FIND")
                        .font(.custom("PermanentMarker-Regular", size: 20))
                        .foregroundStyle(
                            LinearGradient(hexColors: ["#243949", "#517fa4"],
                                           direction: .leftToRight)
                        )
                        .shadow(radius: 34)
                }
            }
            //                .overlay(alignment: .bottomTrailing) {
            //                    Button {
            //                        // TODO: new chat flow
            //                    } label: {
            //                        Image(systemName: "plus")
            //                            .font(.system(size: 24))
            //                            .padding()
            //                            .background(
            //                                LinearGradient(hexColors: ["#243949", "#517fa4"],
            //                                               direction: .topToBottom)
            //                            )
            //                            .foregroundStyle(.white)
            //                            .clipShape(Circle())
            //                            .shadow(radius: 4)
            //                    }
            //                    .padding()
            //                }
        }
        
        .onAppear {
            Task {
                await viewModel.loadAllUsers()
            }
        }
        .onChange(of: viewModel.selectedChat, { _, chat in
            if let chat = chat {
                router.goToChat(chat)
                viewModel.selectedChat = nil
            }
        })
        .tint(Color(hex: "#243949"))
    }
}

struct ChatList: View {
    let chats: [Chat]
    @Binding var path: [Route]
    @State private var showDeleteConfirm = false
    @State private var chatToDelete: Chat? = nil
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var router: Router
    
    var body: some View {
        List(chats) { chat in
            NavigationLink(value: Route.chat(chat)) {
                ChatRow(chat: chat,
                        formattedDate: chat.lastMessage.map { $0.timestamp.chatFormatted() } ?? "")
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
                    .fill(LinearGradient(hexColors: ["#243949", "#517fa4"],
                                         direction: .leftToRight))
                    .frame(width: 40, height: 40)
                    .overlay(Text(homeVM.chatDisplayName(chat).prefix(1))
                        .foregroundStyle(.white))
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
