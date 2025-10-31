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
        ZStack {
            // Messages ScrollView
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message, viewModel: viewModel)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 64)
                }
                .onChange(of: viewModel.messages) { oldMessages, newMessages in
                    guard let newMessage = newMessages.last,
                          newMessages.count > oldMessages.count else { return }
                    
                    if newMessage.isMe { // 👈 Only scroll when I send
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.interpolatingSpring(stiffness: 180, damping: 22)) {
                                scrollProxy.scrollTo(newMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .onAppear {
                    // When view opens, scroll smoothly to bottom
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        if let lastId = viewModel.messages.last?.id {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                scrollProxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            VStack {
                Spacer()
                MessageInputView(viewModel: viewModel)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
            }
            
        }
        .navigationTitle("") // hide default title
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false) // ✅ Hide system back button
        .background(Color.clear)
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
    @ObservedObject var viewModel: ChatViewModel
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
                    if let status = message.status, let id = message.id {
                        TickStatusView(
                            status: status,
                            shouldAnimate: viewModel.animatedMessageIDs.contains(id)
                        )
                    }
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

// MARK: - Message Input View
struct MessageInputView: View {
    @ObservedObject var viewModel: ChatViewModel
    @StateObject private var motion = MotionManager()
    
    var body: some View {
        HStack(spacing: 12) {
            // Text Field with Liquid Glass Effect
            TextField("Type a message...", text: $viewModel.newMessage)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .frame(height: 48)
                .foregroundStyle(.white.opacity(0.9))
                .tint(.white)
                .font(.system(size: 16, weight: .regular))
                .background {
                    ThickLiquidGlassBackground(motion: motion)
                }
                .clipShape(RoundedRectangle(cornerRadius: 29))
            
            // Send Button
            Button(action: { viewModel.sendMessage() }) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background {
                        ZStack {
                            // Blurred background fill
                            ThickLiquidGlassBackground(motion: motion)
                                .clipShape(Circle())
                            
                            // Sharp overlay on top
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.gray.opacity(0.6),
                                            Color.gray.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        }
                        .shadow(color: .white.opacity(0.4), radius: 20, y: 5)
                    }
            }
            .disabled(viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
}
