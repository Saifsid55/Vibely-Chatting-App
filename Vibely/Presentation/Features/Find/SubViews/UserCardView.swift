//
//  Untitled.swift
//  Vibely
//
//  Created by Mohd Saif on 19/12/25.
//

// UserCardView.swift

import SwiftUI

struct UserCardView: View {
    
    let user: AppUser
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            AsyncImage(url: URL(string: user.imageURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Text(user.name)
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(1)
            
            Text(user.profession)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            HStack(spacing: 6) {
                Text("\(user.age)")
                Text("•")
                Text(user.gender.rawValue)
            }
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}
