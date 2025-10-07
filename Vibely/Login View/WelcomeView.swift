//
//  WelcomeView.swift
//  Vibely
//
//  Created by Mohd Saif on 07/10/25.
//

import SwiftUI

// MARK: - Welcome Screen
struct WelcomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showLogin = false
    @State private var showSignup = false
    
    var body: some View {
        ZStack {
            // Background Image
            Image("welcome_screen") // Replace with your image asset name
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // Gradient Overlay
            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // App Logo/Title
                Text("FIND")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                
                Spacer()
                
                VStack(spacing: 16) {
                    // Tagline
                    VStack(spacing: 8) {
                        Text("Dont wait.")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Get best experience now")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 24)
                    
                    // Login Button
                    Button {
                        showLogin = true
                    } label: {
                        Text("Log in")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                    }
                    
                    // Sign Up Button
                    Button {
                        showSignup = true
                    } label: {
                        Text("Don't have an Account? Sign Up")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
                .environmentObject(authVM)
        }
        .fullScreenCover(isPresented: $showSignup) {
            SignupView()
                .environmentObject(authVM)
        }
    }
}
