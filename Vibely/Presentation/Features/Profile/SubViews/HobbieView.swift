//
//  HobbieView.swift
//  Vibely
//
//  Created by Mohd Saif on 21/11/25.
//

import SwiftUI


//
//  HobbyTagView.swift
//  Vibely
//
//  Created by Mohd Saif on 21/11/25.
//

import SwiftUI

struct HobbyTagView: View {
    let hobby: String
    
    var body: some View {
        Text(hobby)
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
}

struct HobbiesRow: View {
    let hobbies: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(hobbies, id: \.self) { hobby in
                    HobbyTagView(hobby: hobby)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
