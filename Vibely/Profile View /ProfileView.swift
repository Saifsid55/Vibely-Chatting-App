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
            
            Button(role: .destructive) {
                vm.signOut()
            } label: {
                Text("Logout")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            Button("Delete Account") {
                Task {
                    do {
                        try await vm.deleteUserAccount()
                        print("✅ Account deleted successfully")
                        // Navigate back to login/signup screen
                    } catch {
                        print("❌ Failed to delete account:", error.localizedDescription)
                    }
                }
            }
            
            Spacer()
        }
    }
}
