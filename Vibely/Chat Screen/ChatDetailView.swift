//
//  ChatDetailView.swift
//  Vibely
//
//  Created by Mohd Saif on 06/09/25.
//
import SwiftUI

struct ChatDetailView: View {
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(chat: Chat) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(chat: chat))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages ScrollView
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Input Bar
            HStack(spacing: 8) {
                TextField("Type a message...", text: $viewModel.newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 8)
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(Color(.systemGray6))
        }
        .navigationTitle("") // Hide default title
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { // Changed from .navigation to .principal
                ChatToolbarContent(
                    chatName: viewModel.chatName,
                    chatInitial: viewModel.chatInitial,
                    avatarURL: viewModel.chat.avatarURL,   // ✅ pass avatar
                    isOnline: true
                )
            }
        }
        .gesture(
            // Add drag gesture to handle swipe back manually
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 && abs(value.translation.height) < 50 {
                        dismiss()
                    }
                }
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}


struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isMe { Spacer() }
            
            Group {
                switch message.messageType {
                case .text:
                    Text(message.text ?? "")
                        .padding(8)
                case .image:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                case .audio:
                    Image(systemName: "waveform")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 50)
                }
            }
            .background(message.isMe ? Color.blue : Color.gray.opacity(0.3))
            .foregroundColor(message.isMe ? .white : .black)
            .cornerRadius(16)
            .frame(maxWidth: 250, alignment: message.isMe ? .trailing : .leading)
            
            if !message.isMe { Spacer() }
        }
    }
}



struct ChatToolbarContent: View {
    let chatName: String
    let chatInitial: String
    let avatarURL: String?     // ✅ Add avatar URL
    let isOnline: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "chevron.left")
                .foregroundColor(.blue)
            
            if let url = avatarURL, !url.isEmpty {
                AsyncImage(url: URL(string: url)) { image in
                    image.resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.blue)
                        .overlay(Text(chatInitial).foregroundColor(.white))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
                    .overlay(Text(chatInitial).foregroundColor(.white))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(chatName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(isOnline ? "Online" : "Offline")
                    .font(.subheadline)
                    .foregroundColor(isOnline ? .green : .gray)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

