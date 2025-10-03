//
//  UserNameView.swift
//  Vibely
//
//  Created by Mohd Saif on 02/10/25.
//

import SwiftUI
import FirebaseAuth

struct UsernameView: View {
    @EnvironmentObject var vm: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose a username")
                .font(.title2)
            
            TextField("Enter username", text: $vm.username)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            Button("Confirm") {
                Task {
                    let available = await vm.checkUsernameAvailable()
                    if available, let uid = Auth.auth().currentUser?.uid {
                        await vm.createUserProfile(uid: uid, email: vm.email.isEmpty ? nil : vm.email, phone: vm.phoneNumber.isEmpty ? nil : vm.phoneNumber)
//                        vm.showUsernameScreen = false
//                        vm.isAuthenticated = true
                    } else {
                        vm.errorMessage = "Username already taken"
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
