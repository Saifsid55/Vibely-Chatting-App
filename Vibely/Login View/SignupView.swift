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
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        ZStack {
            // Background Image (Blurred)
            Image("welcome_screen")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .blur(radius: 4)
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
            
//            GeometryReader {  geo in
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(.leading, 8)
                                .padding(.top, 4)
                        }
                        
                        Spacer()
                        
                        Text("SIGN UP")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.trailing, 8)
                            .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    // App Title
                    Text("FIND")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                    
                    Text("Create your own itinerary!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.bottom, 40)
                    
                    // Signup Form Card
                    VStack(spacing: 20) {
                        // Email Field
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.white)
                            TextField("", text: $email)
                                .placeholder(when: email.isEmpty) {
                                    Text("Enter Email")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .foregroundColor(.white)
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
                                .foregroundColor(.white)
                            
                            if showPassword {
                                TextField("", text: $password)
                                    .placeholder(when: password.isEmpty) {
                                        Text("Password")
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .foregroundColor(.white)
                            } else {
                                SecureField("", text: $password)
                                    .placeholder(when: password.isEmpty) {
                                        Text("Password")
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .foregroundColor(.white)
                            }
                            
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.3))
                        )
                        
                        // Confirm Password Field
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white)
                            
                            if showConfirmPassword {
                                TextField("", text: $confirmPassword)
                                    .placeholder(when: confirmPassword.isEmpty) {
                                        Text("Confirm Password")
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .foregroundColor(.white)
                            } else {
                                SecureField("", text: $confirmPassword)
                                    .placeholder(when: confirmPassword.isEmpty) {
                                        Text("Confirm Password")
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .foregroundColor(.white)
                            }
                            
                            Button {
                                showConfirmPassword.toggle()
                            } label: {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.3))
                        )
                        
                        // Password Match Indicator
                        if !password.isEmpty && !confirmPassword.isEmpty {
                            HStack {
                                Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(password == confirmPassword ? .green : .red)
                                Text(password == confirmPassword ? "Passwords match" : "Passwords do not match")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                        }
                        
                        // Signup Button
                        Button {
                            Task {
                                if password != confirmPassword {
                                    authVM.errorMessage = "Passwords do not match"
                                    return
                                }
                                
                                authVM.email = email
                                authVM.password = password
                                
                                do {
                                    try await authVM.signupWithEmail()
                                } catch {
                                    authVM.errorMessage = error.localizedDescription
                                }
                            }
                        } label: {
                            Text("Create Account")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(25)
                        }
                        .padding(.top, 8)
                        .disabled(email.isEmpty || password.isEmpty || confirmPassword.isEmpty || password != confirmPassword)
                        .opacity((email.isEmpty || password.isEmpty || confirmPassword.isEmpty || password != confirmPassword) ? 0.6 : 1.0)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(height: 1)
                            Text("Or sign up with")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 8)
                        
                        // Google Sign Up Button
                        Button {
                            // Handle Google Sign Up
                            Task {
                                // Add your Google Sign Up logic here
                            }
                        } label: {
                            HStack {
                                Image(systemName: "g.circle.fill") // Replace with Google logo
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
                    
                    Spacer()
                    
                    if let error = authVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.white)
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

// MARK: - Helper Extension for Placeholder
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
