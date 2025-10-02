//
//  VibelyApp.swift
//  Vibely
//
//  Created by Mohd Saif on 06/09/25.
//

import SwiftUI
import Firebase

@main
struct VibelyApp: App {
    
    @StateObject private var authVM = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        Group {
            if authVM.isAuthenticated {
                HomeView()
            } else if authVM.showUsernameScreen {
                UsernameView(vm: authVM)
            } else {
                LoginView()
            }
        }
    }
}
