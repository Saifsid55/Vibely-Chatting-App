//
//  ProfileView.swift
//  Vibely
//
//  Created by Mohd Saif on 17/09/25.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    
    var body: some View {
        ZStack {
            // Background Image (Blurred)
            Image("welcome_screen")
                       .resizable()
                       .aspectRatio(contentMode: .fill)
                       .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                       .blur(radius: 5)
                       .edgesIgnoringSafeArea(.all)
            
            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            
//            GeometryReader { geo in
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(.leading, 8)
                                .padding(.top, 4)
                            
                        }
                        
                        Spacer()
                        
                        Text("LOG IN")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.trailing, 8)
                            .padding(.top, 4)
                        
                    }
                    
                    Spacer()
                    
                    // App Title
                    Text("FIND")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(radius: 5)
                    
                    Text("Create your own itinerary!")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.bottom, 40)
                    
                    // Login Form Card
                    VStack(spacing: 20) {
                        // Email Field
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.white)
                            TextField("", text: $email)
                                .placeholder(when: email.isEmpty) {
                                    Text("Enter Email")
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .foregroundStyle(.white)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.3))
                        )
                        
                        // Password Field
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.white)
                            
                            if showPassword {
                                TextField("", text: $password)
                                    .placeholder(when: password.isEmpty) {
                                        Text("Password")
                                            .foregroundStyle(.white.opacity(0.7))
                                    }
                                    .foregroundStyle(.white)
                            } else {
                                SecureField("", text: $password)
                                    .placeholder(when: password.isEmpty) {
                                        Text("Password")
                                            .foregroundStyle(.white.opacity(0.7))
                                    }
                                    .foregroundStyle(.white)
                            }
                            
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.3))
                        )
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            Button {
                                // Handle forgot password
                            } label: {
                                Text("Forgot Password")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        // Login Button
                        Button {
                            Task {
                                authVM.email = email
                                authVM.password = password
                                await authVM.loginWithEmail()
                            }
                        } label: {
                            Text("Log in")
                                .font(.headline)
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(25)
                        }
                        .padding(.top, 8)
                        .disabled(email.isEmpty || password.isEmpty)
                        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(height: 1)
                            Text("Or log in using")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 8)
                        
                        // Google Sign In Button
                        Button {
                            // Handle Google Sign In
                            Task {
                                // Add your Google Sign In logic here
                            }
                        } label: {
                            HStack {
                                Image(systemName: "g.circle.fill") // Replace with Google logo
                                    .font(.title2)
                                Text("Gmail")
                                    .font(.headline)
                            }
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                        }
                    }
                    

                    .padding(.horizontal, 32)
                    .padding(.vertical, 40)
                    .background(
                        VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                    )
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    if let error = authVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.red.opacity(0.7))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
//            }
        }
        .onChange(of: authVM.isAuthenticated) { _, newValue in
            if newValue {
                dismiss()
            }
        }
    }
}


struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
