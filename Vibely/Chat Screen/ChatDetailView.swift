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
            ToolbarItem(placement: .navigation) {
                ChatToolbarView(
                    chatName: viewModel.chatName,
                    chatInitial: viewModel.chatInitial,
                    isOnline: true
                ) {
                    dismiss()
                }
//                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // Keeps input above keyboard
    }
}


struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.sender == .me { Spacer() }
            
            Group {
                switch message.type {
                case .text:
                    Text(message.text ?? "")
                        .padding(8)
                case .image:
                    Image(systemName: "photo") // Placeholder
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                case .audio:
                    Image(systemName: "waveform") // Placeholder
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 50)
                }
            }
            .background(message.sender == .me ? Color.blue : Color.gray.opacity(0.3))
            .foregroundColor(message.sender == .me ? .white : .black)
            .cornerRadius(16)
            .frame(maxWidth: 250, alignment: message.sender == .me ? .trailing : .leading)
            
            if message.sender == .other { Spacer() }
        }
    }
}


struct ChatToolbarView: View {
    let chatName: String
    let chatInitial: String
    let isOnline: Bool
    let onBack: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
            }
            
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(chatInitial)
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(chatName).font(.headline)
                Text(isOnline ? "Online" : "Offline")
                    .font(.subheadline)
                    .foregroundColor(isOnline ? .green : .gray)
            }
            
            Spacer()
        }
    }
}
