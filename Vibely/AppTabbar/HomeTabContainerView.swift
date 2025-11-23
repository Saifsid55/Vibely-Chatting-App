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
    case profileTwo = "chevron.up"
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .chat: return "Chats"
        case .profile: return "Profile"
        case .profileTwo: return "ProfileTwo"
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
                    case .profileTwo:
                        ProfileView()
                            .id(tabRouter.selectedTab)
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
    
    // MARK: Use your icon from Assets.xcassets
    private let collapseIconAssetName = "left-arrow"
    
    var body: some View {
        ZStack {
            
            // MARK: Collapsed State
            if tabRouter.isTabBarCollapsed && selectedTab == .profile {
                collapsedCircleButton
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                
            } else {
                
                // MARK: Full Tab Bar
                fullTabBar
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        )
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            tabRouter.isTabBarCollapsed = true
                            tabRouter.allowCollapse = true
                        }
                    }
            }
        }
        .animation(
            .spring(response: 0.48, dampingFraction: 0.85, blendDuration: 0.25),
            value: tabRouter.isTabBarCollapsed
        )
    }
    
    
    // MARK: Full Tab Bar UI (unchanged)
    private var fullTabBar: some View {
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
    
    
    // MARK: Collapsed Floating Circle
    private var collapsedCircleButton: some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                tabRouter.isTabBarCollapsed = false
                tabRouter.allowCollapse = false
            }
            
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            
        } label: {
            
            Image(collapseIconAssetName)     // <— USE ASSET HERE
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)
                .padding(18)
                .background{
                    ZStack {
                        CustomBlurView(style: .systemChromeMaterialDark, intensity: 1.0)
                            .clipShape(Circle())
                        
                        Circle()
                            .fill(Color.white.opacity(0.08)) // optional subtle tint
                    }
                }
                .shadow(radius: 10)
        }
        .padding(.trailing, 18)
        .padding(.bottom, 18)
    }
    
    
    // MARK: Tab Buttons (unchanged)
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
            .background(
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
            )
            .foregroundStyle(selectedTab == tab ? .white : Color(hex: "#243949").opacity(0.8))
        }
    }
}
