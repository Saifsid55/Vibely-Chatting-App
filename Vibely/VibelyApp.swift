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
    
    func application(_ application: UIApplication,
                      supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
         return .portrait
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
    @StateObject private var profileVM = ProfileViewModel()
    @StateObject private var mediaBarViewModel = MediaBarViewModel()

    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
                .environmentObject(homeVM)     // ✅ Shared to HomeView, ChatDetailView etc.
                .environmentObject(router)
                .environmentObject(tabRouter)
                .environmentObject(profileVM)
                .environmentObject(mediaBarViewModel)
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

#if canImport(HotSwiftUI)
@_exported import HotSwiftUI
#elseif canImport(Inject)
@_exported import Inject
#else
// This code can be found in the Swift package:
// https://github.com/johnno1962/HotSwiftUI or
// https://github.com/krzysztofzablocki/Inject

#if DEBUG
import Combine

public class InjectionObserver: ObservableObject {
    public static let shared = InjectionObserver()
    @Published var injectionNumber = 0
    var cancellable: AnyCancellable? = nil
    let publisher = PassthroughSubject<Void, Never>()
    init() {
        cancellable = NotificationCenter.default.publisher(for:
            Notification.Name("INJECTION_BUNDLE_NOTIFICATION"))
            .sink { [weak self] change in
            self?.injectionNumber += 1
            self?.publisher.send()
        }
    }
}

extension SwiftUI.View {
    public func eraseToAnyView() -> some SwiftUI.View {
        return AnyView(self)
    }
    public func enableInjection() -> some SwiftUI.View {
        return eraseToAnyView()
    }
    public func onInjection(bumpState: @escaping () -> ()) -> some SwiftUI.View {
        return self
            .onReceive(InjectionObserver.shared.publisher, perform: bumpState)
            .eraseToAnyView()
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
public struct ObserveInjection: DynamicProperty {
    @ObservedObject private var iO = InjectionObserver.shared
    public init() {}
    public private(set) var wrappedValue: Int {
        get {0} set {}
    }
}
#else
extension SwiftUI.View {
    @inline(__always)
    public func eraseToAnyView() -> some SwiftUI.View { return self }
    @inline(__always)
    public func enableInjection() -> some SwiftUI.View { return self }
    @inline(__always)
    public func onInjection(bumpState: @escaping () -> ()) -> some SwiftUI.View {
        return self
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
public struct ObserveInjection {
    public init() {}
    public private(set) var wrappedValue: Int {
        get {0} set {}
    }
}
#endif
#endif
