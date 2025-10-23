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
    
    init(chat: Chat, allUsers: [String: AppUserModel]) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(chat: chat, allUsers: allUsers))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages ScrollView
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                .onChange(of: viewModel.messages.count) { oldValue, newValue in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation(.easeOut(duration: 0.2)) {
                            scrollProxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    // Initial scroll when view appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if let lastId = viewModel.messages.last?.id {
                            scrollProxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
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
                        .foregroundStyle(.blue)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .disabled(viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(Color(.systemGray6))
        }
        .navigationTitle("") // hide default title
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false) // ✅ Hide system back button
        .tint(Color(hex: "#243949"))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                ChatToolbarView(
                    chatName: viewModel.chatName,
                    chatInitial: viewModel.chatInitial,
                    avatarURL: viewModel.chatAvatarURL,
                    onDismiss: { dismiss() }
                )
            }
        }
    }
}


struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack(spacing: 0) {
            if !message.isMe {
                // Receiver messages on the left
                bubbleContent
                    .padding(.leading)
                Spacer()
            } else {
                // Sender messages on the right
                Spacer()
                HStack(alignment: .center, spacing: 8) {
                    Text(message.status?.rawValue.capitalized ?? "Sent")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    bubbleContent
                }
                .padding(.trailing)
            }
        }
    }
    
    private var bubbleContent: some View {
        Group {
            switch message.messageType {
            case .text:
                Text(message.text ?? "")
                    .padding(12)
                    .background(
                        message.isMe
                        ? AnyShapeStyle(
                            LinearGradient(hexColors: ["#243949"], direction: .leftToRight)
                        )
                        : AnyShapeStyle(Color.gray.opacity(0.3))
                    )
                    .foregroundStyle(message.isMe ? .white : .black)
                    .cornerRadius(16, corners: message.isMe ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
            case .image:
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .clipped()
                    .cornerRadius(16)
            case .audio:
                HStack {
                    Image(systemName: "waveform")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                    Text("Audio")
                        .foregroundStyle(.white)
                        .font(.caption)
                }
                .padding(12)
                .background(message.isMe ? Color.blue : Color.gray.opacity(0.3))
                .cornerRadius(16)
            }
        }
        //        .frame(maxWidth: 250, alignment: message.isMe ? .trailing : .leading)
    }
}

// Rounded corners helper
struct RoundedCorner: Shape {
    var radius: CGFloat = 16
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}


struct ChatToolbarView: View {
    let chatName: String
    let chatInitial: String
    let avatarURL: String?
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Back Button
            //            Button(action: {
            //                onDismiss()
            //            }) {
            //                Image(systemName: "chevron.left")
            //                    .foregroundColor(.blue)
            //            }
            
            // Avatar
            if let url = avatarURL, !url.isEmpty, let avatarURL = URL(string: url) {
                AsyncImage(url: avatarURL) { image in
                    image.resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(LinearGradient(hexColors: ["#243949", "#517fa4"], direction: .leftToRight))
                        .overlay(Text(chatInitial).foregroundStyle(.white))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(LinearGradient(hexColors: ["#243949", ""], direction: .leftToRight))
                    .frame(width: 40, height: 40)
                    .overlay(Text(chatInitial).foregroundStyle(.white))
            }
            
            // Name and status
            VStack(alignment: .leading, spacing: 2) {
                Text(chatName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("Online")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
        }
    }
}


