//
//  ChatDetailView.swift
//  Vibely
//
//  Created by Mohd Saif on 06/09/25.
//
import SwiftUI

struct ChatDetailView: View {
    let chat: Chat
    
    var body: some View {
        VStack {
            Text("Chat with \(chat.name)")
                .font(.largeTitle)
                .padding()
            
            Spacer()
        }
        .navigationTitle(chat.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
