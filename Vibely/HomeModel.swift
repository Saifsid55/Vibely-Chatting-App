//
//  HomeModel.swift
//  Vibely
//
//  Created by Mohd Saif on 06/09/25.
//

import Foundation

struct Chat: Identifiable, Hashable {
    let id: UUID
    let name: String
    let lastMessage: String
    let timestamp: Date
    let avatarURL: String?
}
