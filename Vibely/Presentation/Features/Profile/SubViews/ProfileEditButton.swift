//
//  ProfileEditButton.swift
//  Vibely
//
//  Created by Mohd Saif on 15/11/25.
//

import SwiftUI

struct ProfileCoverEditButtons: View {
    let onEditProfileDetails: () -> Void
    let onEditCover: () -> Void
    
    var body: some View {
        HStack {
            // LEFT — Edit Profile Details
            Button(action: onEditProfileDetails) {
                Text("Edit Profile")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background {
                        CustomBlurView(style: .prominent, intensity: 1.0)
                    }
                    .clipShape(Capsule())
                    .foregroundStyle(.black)
            }
            .padding(.leading, 16)
            
            Spacer()
            
            // RIGHT — Edit Cover Photo
            Button(action: onEditCover) {
                ZStack {
                    Asset.editImage.swiftUIImage
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.black)
                        .padding(4)    // internal space for icon
                }
                .frame(width: 32, height: 32)   // perfect circle size
                .background {
                    CustomBlurView(style: .prominent, intensity: 1.0)
                }
                .clipShape(Circle())
            }
            .padding(.trailing, 16)
        }
        .padding(.top, 32)
    }
}
