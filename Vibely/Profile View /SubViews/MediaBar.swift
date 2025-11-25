//
//  MediaBar.swift
//  Vibely
//
//  Created by Mohd Saif on 25/11/25.


import SwiftUI

struct MediaBar: View {
    
    @State private var expandSpotify = false
    @State private var expandYouTube = false
    
    let totalWidth = UIScreen.main.bounds.width
    let horizontalPadding: CGFloat = 32
    let spacing: CGFloat = 12
    let collapsedWidth: CGFloat = 44
    
    var body: some View {
        HStack(spacing: 12) {
            
            musicButton(
                expanded: $expandSpotify,
                otherExpanded: $expandYouTube,
                selectedIcon: "spotifySelected",
                unselectedIcon: "spotifyUnselected",
                title: "Spotify",
                width: expandYouTube ? bothExpandedWidth : singleExpandedWidth
            )
            
            musicButton(
                expanded: $expandYouTube,
                otherExpanded: $expandSpotify,
                selectedIcon: "youtubeSelected",
                unselectedIcon: "youtubeUnselected",
                title: "YouTube",
                width: expandSpotify ? bothExpandedWidth : singleExpandedWidth
            )
        }
        .padding(.horizontal)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: expandSpotify)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: expandYouTube)
    }
    
    var singleExpandedWidth: CGFloat {
        totalWidth - horizontalPadding - collapsedWidth - spacing
    }
    
    // both expanded
    var bothExpandedWidth: CGFloat {
        (totalWidth - horizontalPadding - spacing) / 2
    }
    
    
    // MARK: Reusable Button Builder
    @ViewBuilder
    func musicButton(
        expanded: Binding<Bool>,
        otherExpanded: Binding<Bool>,
        selectedIcon: String,
        unselectedIcon: String,
        title: String,
        width: CGFloat
    ) -> some View {
        
        HStack(spacing: expanded.wrappedValue ? 8 : 0) {
            
            Image(expanded.wrappedValue ? selectedIcon : unselectedIcon)
                .resizable()
                .scaledToFit()
                .padding(.leading, 0)
                .frame(
                    width: expanded.wrappedValue ? 50 : 44,
                    height: expanded.wrappedValue ? 50 : 44,
                )
                .onTapGesture {
                    withAnimation {
                        expanded.wrappedValue.toggle()
                        //                otherExpanded.wrappedValue = false  // Single expansion
                    }
                }
            
            
            if expanded.wrappedValue {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .padding(.vertical, 4)
            }
        }
        .frame(
            width: expanded.wrappedValue ? width : 44,
            height: expanded.wrappedValue ? 50 : 44,
            alignment: .leading
        )
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .contentShape(Rectangle())
    }
}
