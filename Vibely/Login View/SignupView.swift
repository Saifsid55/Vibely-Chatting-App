//
//  SignupView.swift
//  Vibely
//
//  Created by Mohd Saif on 03/10/25.
//
import SwiftUI

struct SignupView: View {
    
    @EnvironmentObject var vm: AuthViewModel
    @State private var confirmPassword = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Email", text: $vm.email)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
            
            SecureField("Password", text: $vm.password)
                .textFieldStyle(.roundedBorder)
            
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(.roundedBorder)
            
            Button("Signup") {
                Task {
                    if vm.password != confirmPassword {
                        vm.errorMessage = "Passwords do not match"
                        return
                    }
                    
                    do {
                        try await vm.signupWithEmail()
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
