//
//  MediaEditPopup.swift
//  Vibely
//
//  Created by Mohd Saif on 30/11/25.
//
import SwiftUI

struct MediaEditPopup: View {
    @ObservedObject var vm: MediaBarViewModel
    let type: MediaType
    let onClose: () -> Void
    
    @State private var urlText: String = ""
    @FocusState private var isFocused: Bool
    
    
    
    var body: some View {
        ZStack {
            // Popup card
            VStack(spacing: 16) {
                
                Text(vm.selectedMedia == .spotify ? "Edit Spotify Link" : "Edit YouTube Link")
                    .font(.headline)
                    .padding(.top, 8)
                
                TextField("Enter URL", text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 16))
                    .padding(.horizontal)
                    .focused($isFocused)
                
                Button(action: {
                    if type == .spotify {
                        if var song = vm.spotifySong {
                            song = SpotifySong(
                                id: song.id,
                                title: song.title,
                                artist: song.artist,
                                thumbnailURL: song.thumbnailURL,
                                previewURL: song.previewURL,
                                externalURL: urlText
                            )
                            vm.spotifySong = song
                        }
                    } else {
                        if var video = vm.youtubeVideo {
                            video = YouTubeVideo(
                                id: video.id,
                                title: video.title,
                                thumbnailURL: video.thumbnailURL,
                                externalURL: urlText
                            )
                            vm.youtubeVideo = video
                        }
                    }
                    onClose()
                }) {
                    Text(resolveButtonLabel())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                Button("Cancel") {
                    onClose()
                }
                .padding(.bottom, 12)
                
            }
            .frame(width: 300, height: 250)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 20)
            .onAppear {
                if type == .spotify {
                    urlText = vm.spotifySong?.externalURL ?? ""
                } else {
                    urlText = vm.youtubeVideo?.externalURL ?? ""
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
            }
        }
    }
    
    private func resolveButtonLabel() -> String {
        if vm.selectedMedia == .spotify {
            return (vm.spotifySong?.externalURL.isEmpty == false) ? "Update" : "Add"
        } else {
            return (vm.youtubeVideo?.externalURL.isEmpty == false) ? "Update" : "Add"
        }
    }
}
