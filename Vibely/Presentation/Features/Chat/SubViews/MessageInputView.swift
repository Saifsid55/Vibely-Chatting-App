//
//  Untitled.swift
//  Vibely
//
//  Created by Mohd Saif on 07/11/25.
//
import SwiftUI

// MARK: - Message Input View
struct MessageInputView: View {
    @ObservedObject var viewModel: ChatViewModel
    @StateObject private var motion = MotionManager(enableMotion: false)
    
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
