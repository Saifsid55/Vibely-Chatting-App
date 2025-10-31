//
//  TabRouter.swift
//  Vibely
//
//  Created by Mohd Saif on 01/11/25.
//

import SwiftUI

@MainActor
final class TabRouter: ObservableObject {
    @Published var selectedTab: TabBarItem = .home
    @Published var isTabBarVisible: Bool = true
}
