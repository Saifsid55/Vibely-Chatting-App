//
//  ProfileView.swift
//  Vibely
//
//  Created by Mohd Saif on 17/09/25.
//

import SwiftUI

// MARK: - Login View
struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthViewModel
    
    // ✅ UI-only state
    @State private var showPassword = false
    @State private var offsetY: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background
            Image("welcome_screen")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blur(radius: 5)
                .edgesIgnoringSafeArea(.all)
            
            LinearGradient(
                colors: [Color.black.opacity(0.3), Color.black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            GeometryReader { _ in
                VStack {
                    // Top Bar
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(.leading, 8)
                            //                                .padding(.top, 16)
                        }
                        
                        Spacer()
                        
                        Text("LOG IN")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.trailing, 8)
                        //                            .padding(.top, 16)
                    }
                    .padding(.top, 16)
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
                    
                    // ✅ Use MVVM-compliant LoginCard
                    LoginCard(showPassword: $showPassword)
                        .environmentObject(authVM)
                    
                    Spacer()
                    
                    // Error message
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
                .offset(y: offsetY)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                offsetY = value.translation.height / 1.5
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring()) {
                                if value.translation.height > 150 {
                                    dismiss()
                                } else {
                                    offsetY = 0
                                }
                            }
                        }
                )
                .animation(.spring(), value: offsetY)
            }
        }
        // ✅ Automatically dismiss when login succeeds
        .onChange(of: authVM.isAuthenticated) { _, newValue in
            if newValue {
                dismiss()
            }
        }
        .onDisappear {
            authVM.resetFields()
        }
    }
}

// MARK: - Login Card View
struct LoginCard: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    // Only UI-specific state here
    @Binding var showPassword: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Email Field
            HStack {
                Image(systemName: "person.fill")
                    .foregroundStyle(.white)
                
                TextField("", text: $authVM.email)
                    .placeholder(when: authVM.email.isEmpty) {
                        Text("Enter Email")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .foregroundStyle(.white)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 25).fill(Color.white.opacity(0.3)))
            
            // Password Field
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.white)
                
                if showPassword {
                    TextField("", text: $authVM.password)
                        .placeholder(when: authVM.password.isEmpty) {
                            Text("Password")
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .foregroundStyle(.white)
                } else {
                    SecureField("", text: $authVM.password)
                        .placeholder(when: authVM.password.isEmpty) {
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
            .background(RoundedRectangle(cornerRadius: 25).fill(Color.white.opacity(0.3)))
            
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
            .disabled(authVM.email.isEmpty || authVM.password.isEmpty)
            .opacity(authVM.email.isEmpty || authVM.password.isEmpty ? 0.6 : 1.0)
            
            // Divider
            HStack {
                Rectangle().fill(Color.white.opacity(0.5)).frame(height: 1)
                Text("Or log in using")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Rectangle().fill(Color.white.opacity(0.5)).frame(height: 1)
            }
            .padding(.vertical, 8)
            
            // Google Sign In
            Button {
                // Add Google Sign In logic here
            } label: {
                HStack {
                    Image(systemName: "g.circle.fill")
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
    }
}



struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
