//
//  EditProfileView.swift
//  Vibely
//
//  Created by Mohd Saif on 15/11/25.
//
import SwiftUI

struct EditProfileDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @StateObject private var vm: EditProfileDetailsViewModel
    
    init(profileVM: ProfileViewModel) {
        _vm = StateObject(wrappedValue: EditProfileDetailsViewModel(profileVM: profileVM))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                
                // MARK: - NON EDITABLE SECTION
                Section("Account Details (Not Editable)") {
                    readOnlyField(label: "Phone Number", value: vm.phoneNumber)
                    readOnlyField(label: "Email", value: vm.email)
                    readOnlyField(label: "Username", value: vm.usernameLowercase)
                }
                
                // MARK: - BASIC INFO
                Section("Basic Information") {
                    TextField("Display Name", text: $vm.fullName)
                    TextField("Bio", text: $vm.bio)
                }
                
                // MARK: - PERSONAL INFO
                Section("Personal Information") {
                    TextField("Gender", text: $vm.gender)
                    TextField("Age", text: $vm.age)
                    TextField("Location", text: $vm.location)
                    TextField("Profession", text: $vm.profession)
                }
                
                // MARK: - SAVE BUTTON
                Section {
                    Button {
                        Task {
                            do {
                                try await vm.saveChanges()
                                dismiss()
                            } catch {
                                print("❌ Save failed:", error.localizedDescription)
                            }
                        }
                    } label: {
                        if vm.isSaving {
                            ProgressView()
                        } else {
                            Text("Save Changes")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .padding(10)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear { vm.loadFromProfile() }
            //            .onChange(of: profileVM.profile) { _, _ in
            //                vm.loadFromProfile()
            //            }
            
        }
    }
    
    // MARK: - Helper for read-only fields
    private func readOnlyField(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
        .disabled(true)
    }
}
