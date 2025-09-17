//
//  ChatDetailModel.swift
//  Vibely
//
//  Created by Mohd Saif on 17/09/25.
//

import Foundation

struct Message: Identifiable, Hashable {
    let id = UUID()
    let text: String?
    let sender: Sender
    let timestamp: Date
    let type: MessageType
}

enum Sender {
    case me
    case other
}

enum MessageType {
    case text
    case image
    case audio
}
