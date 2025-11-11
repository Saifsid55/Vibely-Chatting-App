//
//  HomeTabContainerView.swift
//  Vibely
//
//  Created by Mohd Saif on 31/10/25.
//

import SwiftUI

enum TabBarItem: String, CaseIterable {
    case home = "house.fill"
    case chat = "message.fill"
    case profile = "person.fill"
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .chat: return "Chats"
        case .profile: return "Profile"
        }
    }
}


struct MainTabView: View {
    @EnvironmentObject var tabRouter: TabRouter
    @EnvironmentObject var viewModel: HomeViewModel
    @EnvironmentObject var router: Router
    @Namespace private var animation
    var body: some View {
        ZStack(alignment: .bottom) {
            // Each tab is wrapped by its own NavigationStack bound to the same router.path.
            // This keeps tab bar persistent and allows pushing views on top of current tab.
            NavigationStack(path: $router.path) {
                Group {
                    switch tabRouter.selectedTab {
                    case .home:
                        HomeView()
                        //                            .onAppear { tabRouter.isTabBarVisible = true }
                    case .chat:
                        EmptyView()
                        
                    case .profile:
                        ProfileView()
                            .id(tabRouter.selectedTab)
                    }
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .chat(let chat):
                        ChatDetailView(chat: chat, allUsers: viewModel.allUsersDict)
                        
                    case .profile:
                        ProfileView()
                            .id(tabRouter.selectedTab)
                    }
                }
            }
            .onChange(of: router.path) { oldValue, newValue in
                // Show tab bar only when navigation stack is empty
                withAnimation(.easeInOut(duration: 0.3)) {
                    tabRouter.isTabBarVisible = newValue.isEmpty
                }
            }
            // Tab bar overlay
            if tabRouter.isTabBarVisible {
                CustomTabBarView(selectedTab: $tabRouter.selectedTab, animation: animation)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: tabRouter.isTabBarVisible)
            }
        }
        .onChange(of: tabRouter.selectedTab) { oldTab, newTab in
            if oldTab == .profile && newTab != .profile {
                NotificationCenter.default.post(name: .profileTabDidDisappear, object: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didLogout)) { _ in
            tabRouter.selectedTab = .home
            tabRouter.isTabBarVisible = true
            router.path.removeAll()
            viewModel.allUsersDict.removeAll()
        }
        .ignoresSafeArea(edges: .bottom)
    }
}


struct CustomTabBarView: View {
    @Binding var selectedTab: TabBarItem
    var animation: Namespace.ID
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(TabBarItem.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            BlurView(style: .systemUltraThinMaterialLight)
                .opacity(0.95)
                .background(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.blue.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedTab)
    }
    
    @ViewBuilder
    private func tabButton(for tab: TabBarItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedTab = tab
            }
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: tab.rawValue)
                    .font(.system(size: 20, weight: .semibold))
                    .symbolEffect(.bounce, value: selectedTab == tab)
                
                if selectedTab == tab {
                    Text(tab.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(hexColors: ["#FFFFFF", "#D1D1D1"],
                                           direction: .leftToRight)
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, selectedTab == tab ? 16 : 12)
            .background(
                ZStack {
                    if selectedTab == tab {
                        Capsule()
                            .fill(
                                LinearGradient(hexColors: ["#243949", "#517fa4"],
                                               direction: .leftToRight)
                                
                            )
                            .matchedGeometryEffect(id: "activeTab", in: animation)
                    }
                }
            )
            .foregroundStyle(selectedTab == tab ? .white : .gray)
        }
    }
}
