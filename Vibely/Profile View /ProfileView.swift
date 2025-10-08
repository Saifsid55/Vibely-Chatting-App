//
//  ProfileView.swift
//  Vibely
//
//  Created by Mohd Saif on 03/10/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var vm: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Profile")
                .font(.largeTitle)
                .padding(.top, 40)
            
            Spacer()
            
            // User info section
            VStack(spacing: 12) {
                // Avatar / Initials
                Circle()
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(vm.username.prefix(1).uppercased())
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                    )
                
                // Username
                Text(vm.username)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Email
                if let email = Auth.auth().currentUser?.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
            }
            .padding(.bottom, 40)
            
            Spacer()
            
            // Logout button
            Button(role: .destructive) {
                vm.signOut()
            } label: {
                Text("Logout")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            // Delete account button
            Button("Delete Account") {
                Task {
                    do {
                        try await vm.deleteUserAccount()
                        print("✅ Account deleted successfully")
                        // Optionally trigger navigation back to login screen
                    } catch {
                        print("❌ Failed to delete account:", error.localizedDescription)
                    }
                }
            }
            .foregroundStyle(.red)
            .padding(.top, 10)
            
            Spacer()
        }
    }
}

