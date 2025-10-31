//
//  Router.swift
//  Vibely
//
//  Created by Mohd Saif on 31/10/25.
//

import SwiftUI

@MainActor
final class Router: ObservableObject {
    @Published var path: [Route] = []
    
    func goToChat(_ chat: Chat) {
        path.append(.chat(chat))
    }
    
    func goToProfile() {
        path.append(.profile)
    }
    
    func goBack() {
        if !path.isEmpty { path.removeLast() }
    }
    
    func resetToRoot() {
        path.removeAll()
    }
}
