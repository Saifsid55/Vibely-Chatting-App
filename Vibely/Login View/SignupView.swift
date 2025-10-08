//
//  SignupView.swift
//  Vibely
//
//  Created by Mohd Saif on 03/10/25.
//
import SwiftUI

// MARK: - Signup Screen
struct SignupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthViewModel
    
    // ✅ Only UI-specific states
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var offsetY: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background Image
            Image("welcome_screen")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blur(radius: 4)
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
                        }
                        
                        Spacer()
                        
                        Text("SIGN UP")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.trailing, 8)
                    }
                    .padding(.top, 24)
                    Spacer()
                    
                    // App Title
                    Text("FIND")
//                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .font(.custom("PermanentMarker-Regular", size: 48))
                        .foregroundStyle(.white)
                        .shadow(radius: 5)
                    
                    Text("Create your own itinerary!")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.bottom, 40)
                    
                    // ✅ MVVM Signup Card
                    SignupCardView(showPassword: $showPassword, showConfirmPassword: $showConfirmPassword)
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
        // ✅ Dismiss automatically when signup succeeds
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

// MARK: - Signup Card View
struct SignupCardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    // Only UI-related states
    @Binding var showPassword: Bool
    @Binding var showConfirmPassword: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Email Field
            HStack {
                Image(systemName: "envelope.fill")
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
                                .foregroundColor(.white.opacity(0.7))
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
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 25).fill(Color.white.opacity(0.3)))
            
            // Confirm Password Field
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.white)
                
                if showConfirmPassword {
                    TextField("", text: $authVM.confirmPassword)
                        .placeholder(when: authVM.confirmPassword.isEmpty) {
                            Text("Confirm Password")
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .foregroundStyle(.white)
                } else {
                    SecureField("", text: $authVM.confirmPassword)
                        .placeholder(when: authVM.confirmPassword.isEmpty) {
                            Text("Confirm Password")
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .foregroundStyle(.white)
                }
                
                Button {
                    showConfirmPassword.toggle()
                } label: {
                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 25).fill(Color.white.opacity(0.3)))
            
            // Password Match Indicator
            if !authVM.password.isEmpty && !authVM.confirmPassword.isEmpty {
                HStack {
                    Image(systemName: authVM.password == authVM.confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(authVM.password == authVM.confirmPassword ? .green : .red)
                    Text(authVM.password == authVM.confirmPassword ? "Passwords match" : "Passwords do not match")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            
            // Signup Button
            Button {
                Task {
                    guard authVM.password == authVM.confirmPassword else {
                        authVM.errorMessage = "Passwords do not match"
                        return
                    }
                    
                    do {
                        try await authVM.signupWithEmail()
                    } catch {
                        authVM.errorMessage = error.localizedDescription
                    }
                }
            } label: {
                Text("Create Account")
                    .font(.headline)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(25)
            }
            .padding(.top, 8)
            .disabled(authVM.email.isEmpty || authVM.password.isEmpty || authVM.confirmPassword.isEmpty || authVM.password != authVM.confirmPassword)
            .opacity((authVM.email.isEmpty || authVM.password.isEmpty || authVM.confirmPassword.isEmpty || authVM.password != authVM.confirmPassword) ? 0.6 : 1.0)
            
            // Divider
            HStack {
                Rectangle().fill(Color.white.opacity(0.5)).frame(height: 1)
                Text("Or sign up with")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Rectangle().fill(Color.white.opacity(0.5)).frame(height: 1)
            }
            .padding(.vertical, 8)
            
            // Google Sign Up
            Button {
                // Add Google Sign Up logic here
            } label: {
                HStack {
                    Image(systemName: "g.circle.fill")
                        .font(.title2)
                    Text("Gmail")
                        .font(.headline)
                }
                .foregroundColor(.gray)
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

// MARK: - Helper Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
            
            ZStack(alignment: alignment) {
                placeholder().opacity(shouldShow ? 1 : 0)
                self
            }
        }
}
