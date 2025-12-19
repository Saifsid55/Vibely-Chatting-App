//
//  FindView.swift
//  Vibely
//
//  Created by Mohd Saif on 19/12/25.
//

import SwiftUI

struct FindUsersView: View {
    
    @StateObject private var vm = FindUsersViewModel()
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(vm.users) { user in
                    UserCardView(user: user)
                }
            }
            .padding(16)
        }
        .navigationTitle("Find People")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }
}
