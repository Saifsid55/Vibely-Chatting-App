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
        storeGeminiAPIKeyIfNeeded()
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
    
    
    private func storeGeminiAPIKeyIfNeeded() {
        if KeychainHelper.shared.read(forKey: KeychainKeys.geminiAPIKey) != nil {
            print("✅ Gemini API key already exists in Keychain.")
            return
        }

        // Try environment variable (for CI/CD)
        var apiKey: String? = ProcessInfo.processInfo.environment["GEMINI_API_KEY"]

        // Fallback: read from Info.plist (xcconfig provides this)
        if apiKey == nil || apiKey!.isEmpty {
            apiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String
        }

        if let apiKey, !apiKey.isEmpty {
            KeychainHelper.shared.save(apiKey, forKey: KeychainKeys.geminiAPIKey)
            print("🔑 Gemini API key stored securely in Keychain.")
        } else {
            print("⚠️ GEMINI_API_KEY not found. Key not stored.")
        }
    }

}


@main
struct VibelyApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var homeVM = HomeViewModel()      // ✅ Shared instance
    @StateObject private var router = Router()             // ✅ Handles navigation stack
    @StateObject private var tabRouter = TabRouter()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
                .environmentObject(homeVM)     // ✅ Shared to HomeView, ChatDetailView etc.
                .environmentObject(router)
                .environmentObject(tabRouter)
                .onReceive(NotificationCenter.default.publisher(for: .didLogout)) { _ in
                    resetAppState()
                }
        }
    }
    
    private func resetAppState() {
        // 🧼 Clean everything back to default
        tabRouter.selectedTab = .home
        tabRouter.isTabBarVisible = true
        router.path.removeAll()
        homeVM.allUsersDict.removeAll()
        
        print("🔄 App state reset after logout")
    }
}

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        Group {
            if authVM.isLoading {
                SplashView()
            } else if authVM.isAuthenticated {
                MainTabView()
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
