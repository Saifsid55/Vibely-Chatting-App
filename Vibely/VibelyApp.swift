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
        configureNavigationBarAppearance()
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
    
    
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        // Hide back button title
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        backButtonAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.backButtonAppearance = backButtonAppearance
        
        // Apply to all navigation bars
        //        UINavigationBar.appearance().tintColor = UIColor(hex: "#243949")
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
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
            if authVM.isLoading {
                SplashView() 
            } else if authVM.isAuthenticated {
                HomeView()
            } else if authVM.showUsernameScreen {
                UsernameView()
            } else {
                WelcomeView()
                    .environmentObject(authVM)
            }
        }
        .animation(.easeInOut, value: authVM.isLoading)
        .transition(.opacity)
    }
}
