//
//  ChatToolbarView.swift
//  Vibely
//
//  Created by Mohd Saif on 07/11/25.
//

import SwiftUI


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
                    .fill(LinearGradient(hexColors: ["#243949", "#517fa4"], direction: .leftToRight))
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
