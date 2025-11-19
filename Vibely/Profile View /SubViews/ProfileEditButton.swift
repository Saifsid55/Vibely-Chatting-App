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
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
            .padding(.leading, 16)
            
            Spacer()
            
            // RIGHT — Edit Cover Photo
            Button(action: onEditCover) {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
            .padding(.trailing, 16)
        }
        .padding(.top, 40)
    }
}
