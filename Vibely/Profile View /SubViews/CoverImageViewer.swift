//
//  CoverImageViewer.swift
//  Vibely
//
//  Created by Mohd Saif on 15/11/25.
//
import SwiftUI

struct CoverImageViewer: View {
    @Binding var showFullCoverImage: Bool
    let coverURL: String?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let coverURL = coverURL,
               let url = URL(string: coverURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().tint(.white)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .id(url)
                            .onTapGesture { showFullCoverImage = false }
                    case .failure:
                        Text("Failed to load image")
                            .foregroundStyle(.white)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Text("No Cover Photo")
                    .foregroundStyle(.white)
            }
            
            VStack {
                HStack {
                    Button {
                        showFullCoverImage = false
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
