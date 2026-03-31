//
//  ProfileImageViewer.swift
//  Vibely
//
//  Created by Mohd Saif on 15/11/25.
//
import SwiftUI

struct ProfileImageViewer: View {
    @Binding var showFullProfileImage: Bool
    let profileURL: String?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let profileURL = profileURL,
               let url = URL(string: profileURL) {
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height)
                    VStack {
                        Spacer()
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView().tint(.white)
                                    .frame(width: side, height: side)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: side, height: side)
                                    .background(Color.black)
                                    .onTapGesture { showFullProfileImage = false }
                            case .failure:
                                Text("Failed to load image")
                                    .foregroundStyle(.white)
                                    .frame(width: side, height: side)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                Text("No Profile Photo")
                    .foregroundStyle(.white)
            }
            
            VStack {
                HStack {
                    Button {
                        showFullProfileImage = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(20)
                    }
                    Spacer()
                }
                Spacer()
            }
        }
    }
}
