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
    //    case profileTwo = "chevron.up"
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .chat: return "Chats"
        case .profile: return "Profile"
            //        case .profileTwo: return "ProfileTwo"
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
            
            NavigationStack(path: $router.path) {
                Group {
                    switch tabRouter.selectedTab {
                    case .home:
                        HomeView()
                    case .chat:
                        EmptyView()
                    case .profile:
                        NewProfileView()
                            .id(tabRouter.selectedTab)
                        //                    case .profileTwo:
                        //                        ProfileView()
                        //                            .id(tabRouter.selectedTab)
                    }
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .chat(let chat):
                        ChatDetailView(chat: chat, allUsers: viewModel.allUsersDict)
                    case .profile:
                        NewProfileView()
                            .id(tabRouter.selectedTab)
                    }
                }
            }
            .onChange(of: router.path) { _, newValue in
                withAnimation(.easeInOut(duration: 0.3)) {
                    tabRouter.isTabBarVisible = newValue.isEmpty
                }
            }
            
            
            // MARK: Tab Bar Overlay
            if tabRouter.isTabBarVisible {
                CustomTabBarView(
                    selectedTab: $tabRouter.selectedTab,
                    animation: animation
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
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
    
    @EnvironmentObject var tabRouter: TabRouter
    
    var body: some View {
        HStack(spacing: 0) {
            if selectedTab == .profile {
                // Profile view with collapsible tab bar
                profileTabBar
            } else {
                // Other views - centered tab bar
                regularTabBar
            }
        }
        .frame(maxWidth: .infinity, alignment: selectedTab == .profile ? .trailing : .center)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.85),
            value: tabRouter.isTabBarCollapsed
        )
    }
    
    // MARK: Regular Tab Bar (for home, chat - centered)
    private var regularTabBar: some View {
        HStack(spacing: 12) {
            ForEach(TabBarItem.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background {
            BlurView(style: .systemUltraThinMaterialLight)
                .opacity(0.95)
                .background{
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.blue.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: Profile Tab Bar (collapsible with arrow inside)
    private var profileTabBar: some View {
        HStack(spacing: 12) {
            // Collapsible tab content
            if !tabRouter.isTabBarCollapsed {
                ForEach(TabBarItem.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
            // Toggle button (always visible, inside the capsule)
            toggleButton
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
                .clipShape(tabRouter.isTabBarCollapsed ? AnyShape(Circle()) : AnyShape(Capsule()))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: Toggle Button (rotates in place, styled to match tab bar)
    private var toggleButton: some View {
        Button {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                tabRouter.isTabBarCollapsed.toggle()
            }
            
        } label: {
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "#243949").opacity(0.8))
                .rotationEffect(.degrees(tabRouter.isTabBarCollapsed ? 180 : 0))
                .frame(width: 20, height: 20)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background{
                    Circle()
                        .fill(Color.white.opacity(0.3))
                }
        }
    }
    
    // MARK: Tab Buttons
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
                            LinearGradient(
                                hexColors: ["#FFFFFF", "#D1D1D1"],
                                direction: .leftToRight
                            )
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, selectedTab == tab ? 16 : 12)
            .background {
                ZStack {
                    if selectedTab == tab {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    hexColors: ["#243949", "#517fa4"],
                                    direction: .leftToRight
                                )
                            )
                            .matchedGeometryEffect(id: "activeTab", in: animation)
                    }
                }
            }
            .foregroundStyle(selectedTab == tab ? .white : Color(hex: "#243949").opacity(0.8))
        }
    }
}
