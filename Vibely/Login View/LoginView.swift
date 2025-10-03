//
//  ProfileView.swift
//  Vibely
//
//  Created by Mohd Saif on 17/09/25.
//

import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject var vm: AuthViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome to ChatApp")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Email login
                TextField("Email", text: $vm.email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $vm.password)
                    .textFieldStyle(.roundedBorder)
                
                Button("Login with Email") {
                    Task { await vm.loginWithEmail() }
                }
                
                Divider().padding()
                
                NavigationLink("Signup with Email") {
                    SignupView()
                        .environmentObject(vm)
                }
                
                // Phone auth (optional)
                Divider().padding()
                TextField("Phone (+91...)", text: $vm.phoneNumber)
                    .textFieldStyle(.roundedBorder)
                
                Button("Send OTP") {
                    Task {
                        do {
                            vm.verificationID = try await vm.sendOTP(to: vm.phoneNumber)
                        } catch {
                            vm.errorMessage = error.localizedDescription
                        }
                    }
                }
                
                TextField("OTP Code", text: $vm.otpCode)
                    .textFieldStyle(.roundedBorder)
                
                Button("Verify OTP") {
                    Task {
                        do {
                            try await vm.verifyOTP(vm.otpCode)
                            vm.isAuthenticated = true
                        } catch {
                            vm.errorMessage = error.localizedDescription
                        }
                    }
                }
                
                if let error = vm.errorMessage {
                    Text(error).foregroundColor(.red)
                }
            }
            .padding()
        }
    }
}
