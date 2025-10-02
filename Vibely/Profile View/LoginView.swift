//
//  ProfileView.swift
//  Vibely
//
//  Created by Mohd Saif on 17/09/25.
//


import SwiftUI

struct LoginView: View {
    @StateObject private var vm = AuthViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome to ChatApp")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Email
                TextField("Email", text: $vm.email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                SecureField("Password", text: $vm.password)
                    .textFieldStyle(.roundedBorder)
                
                Button("Login with Email") { Task { await vm.loginWithEmail() } }
                Button("Signup with Email") { Task { await vm.signupWithEmail() } }
                
                Divider().padding()
                
                // Phone
                TextField("Phone (+91...)", text: $vm.phoneNumber)
                    .textFieldStyle(.roundedBorder)
                
                Button("Send OTP") { vm.sendOTP() }
                TextField("OTP Code", text: $vm.otpCode)
                    .textFieldStyle(.roundedBorder)
                
                Button("Verify OTP") { Task { await vm.verifyOTP() } }
                
                if let error = vm.errorMessage {
                    Text(error).foregroundColor(.red)
                }
                
            }
            .padding()
            
            // Navigation for Username Screen
            .navigationDestination(isPresented: $vm.showUsernameScreen) {
                UsernameView(vm: vm)
            }
            // Navigation for Home Screen
            .navigationDestination(isPresented: $vm.isAuthenticated) {
                HomeView()
            }
        }
    }
}
