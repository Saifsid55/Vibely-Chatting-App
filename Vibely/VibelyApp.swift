//
//  VibelyApp.swift
//  Vibely
//
//  Created by Mohd Saif on 06/09/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import UIKit

// 1️⃣ Minimal AppDelegate for Firebase
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
//    // Forward notifications to Firebase Auth
//    func application(_ application: UIApplication,
//                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
//                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        
//        if Auth.auth().canHandleNotification(userInfo) {
//            completionHandler(.noData)
//            return
//        }
//        
//        completionHandler(.newData)
//    }
}


@main
struct VibelyApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authVM = AuthViewModel()
    
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
                UsernameView()
            } else {
                LoginView()
            }
        }
    }
}
