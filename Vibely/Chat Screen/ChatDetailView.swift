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
    @State private var showScrollToBottomButton = false
    @State private var scrollOffset: CGFloat = 0
    
    init(chat: Chat, allUsers: [String: AppUserModel]) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(chat: chat, allUsers: allUsers))
    }
    
    var body: some View {
        ZStack {
            ScrollSection
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .background(Color.clear)
        .tint(Color(hex: "#243949"))
        .toolbar { toolbarContent }
    }
    
    private var ScrollSection: some View {
        ScrollViewReader { scrollProxy in
            ZStack {
                MessagesScrollView(scrollProxy: scrollProxy)
                MessageOverlay(scrollProxy: scrollProxy)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            HStack(spacing: 8) {
                ChatToolbarView(
                    chatName: viewModel.chatName,
                    chatInitial: viewModel.chatInitial,
                    avatarURL: viewModel.chatAvatarURL,
                    onDismiss: { dismiss() }
                )
                
                if let mood = viewModel.userMood {
                    MoodMeterView(mood: mood)
                        .frame(width: 30, height: 22)
                        .padding(.leading, 4)
                }
            }
        }
    }
    
    private func MessagesScrollView(scrollProxy: ScrollViewProxy) -> some View {
        ScrollView {
            
            GeometryReader { geo in
                Color.clear
                    .onChange(of: geo.frame(in: .named("scrollSpace")).minY) { oldValue, newValue in
                        
                        scrollOffset = min(newValue, scrollOffset)
                        
                        let threshold: CGFloat = scrollOffset + 400
                        let newIsNearBottom = newValue > threshold
                        
                        if newIsNearBottom {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showScrollToBottomButton = true
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showScrollToBottomButton = false
                            }
                        }
                    }
            }
            
            LazyVStack(spacing: 10) {
                Color.clear
                    .frame(height: 1)
                    .id("top")
                
                ForEach(viewModel.messages) { message in
                    MessageBubble(message: message, viewModel: viewModel)
                        .id(message.id)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
        }
        .coordinateSpace(.named("scrollSpace"))
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }
        .onChange(of: viewModel.messages) { oldMessages, newMessages in
            handleMessagesChange(oldMessages: oldMessages, newMessages: newMessages, scrollProxy: scrollProxy)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let lastId = viewModel.messages.last?.id {
                    withAnimation(.easeOut(duration: 0.4)) {
                        scrollProxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private func MessageOverlay(scrollProxy: ScrollViewProxy) -> some View {
        VStack {
            Spacer()
            scrollToBottomButton(scrollProxy: scrollProxy)
            MessageInputView(viewModel: viewModel)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
        }
        .background(Color.clear)
    }
    
    private func handleMessagesChange(
        oldMessages: [Message],
        newMessages: [Message],
        scrollProxy: ScrollViewProxy
    ) {
        guard let lastMessage = newMessages.last else { return }
        
        if lastMessage.isMe {
            // 👤 Sent by current user — scroll to bottom
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        } else {
            
        }
    }
    
    @ViewBuilder
    private func scrollToBottomButton(scrollProxy: ScrollViewProxy) -> some View {
        if showScrollToBottomButton {
            Button {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    if let lastId = viewModel.messages.last?.id {
                        scrollProxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            } label: {
                Image(systemName: "arrow.down")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background {
                        ZStack {
                            // Blurred background fill
                            ThickLiquidGlassBackground(motion: MotionManager(enableMotion: false))
                                .clipShape(Circle())
                            
                            // Sharp overlay on top
                            Circle()
                                .strokeBorder(
                                    LinearGradient(hexColors: ["#243949", "#517fa4"], direction: .topToBottom),
                                    lineWidth: 2
                                )
                        }
                        .shadow(color: .white.opacity(0.4), radius: 20, y: 5)
                    }
                    .padding(.bottom, 4)
            }
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(), value: showScrollToBottomButton)
        }
    }
    
    @ViewBuilder
    private func newMessageButton(scrollProxy: ScrollViewProxy) -> some View {
        Button {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                if let lastId = viewModel.messages.last?.id {
                    scrollProxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        } label: {
            Image(systemName: "arrow.down")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(hexColors: ["#243949", "#517fa4"], direction: .leftToRight)
                            )
                        
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
    }
}
