//
//  MessageBubble.swift
//  Vibely
//
//  Created by Mohd Saif on 07/11/25.
//
import SwiftUI

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
