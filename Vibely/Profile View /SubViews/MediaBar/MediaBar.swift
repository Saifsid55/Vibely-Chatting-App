//
//  MediaBar.swift
//  Vibely
//
//  Created by Mohd Saif on 25/11/25.

import SwiftUI
import HotSwiftUI

struct MediaBar: View {
    
    @EnvironmentObject var vm: MediaBarViewModel
    
    let totalWidth = UIScreen.main.bounds.width
    let horizontalPadding: CGFloat = 32
    let spacing: CGFloat = 12
    let collapsedWidth: CGFloat = 44
    
    var body: some View {
        
        let spotifyWidth = vm.expandYouTube ? bothExpandedWidth : singleExpandedWidth
        let youtubeWidth  = vm.expandSpotify ? bothExpandedWidth : singleExpandedWidth
        
        HStack(spacing: spacing) {
            spotifyButton(width: spotifyWidth)
            youtubeButton(width: youtubeWidth)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: vm.expandSpotify)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: vm.expandYouTube)
        .onAppear { vm.loadMockData() }
        .enableInjection()
    }
    
    var singleExpandedWidth: CGFloat {
        totalWidth - horizontalPadding - collapsedWidth - spacing
    }
    
    var bothExpandedWidth: CGFloat {
        (totalWidth - horizontalPadding - spacing) / 2
    }
}

extension MediaBar {
    
    @ViewBuilder
    func spotifyButton(width: CGFloat) -> some View {
        HStack(spacing: vm.expandSpotify ? 8 : 0) {
            
            Image(vm.expandSpotify ? "spotifySelected" : "spotifyUnselected")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: vm.expandSpotify ? 50 : 44,
                       height: vm.expandSpotify ? 50 : 44)
                .clipShape(Circle())
                .rotationEffect(.degrees(vm.expandSpotify ? 360 : 0))
                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: vm.expandSpotify)
                .onTapGesture {
                    HapticManager.shared.lightTap()
                    vm.toggleSpotify()
                }
            
            if vm.expandSpotify, let song = vm.spotifySong {
                HStack(spacing: 6) {
                    
                    SlidingText(text: song.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(1)
                    
                    Button(action: {
                        vm.isPlaying ? vm.pausePreview() : vm.playPreview(url: song.previewURL)
                    }) {
                        Image(systemName: vm.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.black)
                    }
                    .padding(.trailing, 8)
                }
                .frame(height: 44)
                .transition(.opacity)
            }
        }
        .frame(width: vm.expandSpotify ? width : 44,
               height: vm.expandSpotify ? 50 : 44,
               alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}


extension MediaBar {
    
    @ViewBuilder
    func youtubeButton(width: CGFloat) -> some View {
        HStack(spacing: vm.expandYouTube ? 8 : 0) {
            
            Image(vm.expandYouTube ? "youtubeSelected" : "youtubeUnselected")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: vm.expandYouTube ? 50 : 44,
                       height: vm.expandYouTube ? 50 : 44)
                .clipShape(Circle())
                .rotationEffect(.degrees(vm.expandYouTube ? 360 : 0))
                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: vm.expandYouTube)
                .onTapGesture {
                    HapticManager.shared.lightTap()
                    vm.toggleYouTube()
                }
            
            if vm.expandYouTube, let video = vm.youtubeVideo {
                
                HStack(spacing: 0) {
                    SlidingText(text: video.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(1)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            //                            if let url = URL(string: video.externalURL) {
                            //                                UIApplication.shared.open(url)
                            //                            }
                        }
                    Button(action: {
                        if let url = URL(string: video.externalURL) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: vm.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.black)
                    }
                    .padding(.trailing, 8)
                    
                }
                .frame(height: 44)
            }
        }
        .frame(width: vm.expandYouTube ? width : 44,
               height: vm.expandYouTube ? 50 : 44,
               alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}
