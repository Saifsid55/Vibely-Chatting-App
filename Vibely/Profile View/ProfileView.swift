//
//  ProfileView.swift
//  Vibely
//
//  Created by Mohd Saif on 17/09/25.
//
import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(Color.blue)
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(.white)
                }
            
            Text("John Doe")
                .font(.title)
                .bold()
            
            Text("iOS Developer")
                .font(.subheadline)
                .foregroundStyle(.gray)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Profile")
    }
}
