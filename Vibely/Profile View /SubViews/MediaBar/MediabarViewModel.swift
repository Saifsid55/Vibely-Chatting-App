//
//  MediaBarViewModel.swift
//  Vibely
//
//  Created by Mohd Saif on 25/11/25.
//

import SwiftUI
import AVFoundation

class MediaBarViewModel: ObservableObject {
    
    // MARK: - UI State
    @Published var expandSpotify = false
    @Published var expandYouTube = false
    
    // MARK: - Selected Media
    @Published var spotifySong: SpotifySong? = nil
    @Published var youtubeVideo: YouTubeVideo? = nil
    @Published var isPlaying = false
    
    private var player: AVPlayer?
    
    // MARK: - Mock Data
    let mockSpotify = SpotifySong(
        id: "12345",
        title: "Blinding Lights",
        artist: "The Weeknd",
        thumbnailURL: "https://i.scdn.co/image/ab67616d0000b273example",
        previewURL: "https://p.scdn.co/mp3-preview/example",
        externalURL: "spotify:track:12345"
    )
    
    let mockYouTube = YouTubeVideo(
        id: "abcdEFG123",
        title: "Spider-Man Theme Remix",
        thumbnailURL: "https://img.youtube.com/vi/abcdEFG123/maxresdefault.jpg",
        externalURL: "https://youtube.com/watch?v=abcdEFG123"
    )
    
    func loadMockData() {
        self.spotifySong = mockSpotify
        self.youtubeVideo = mockYouTube
    }
    
    // MARK: - Toggle Logic (Pure State)
    
    func toggleSpotify() {
        expandSpotify.toggle()
        if !expandSpotify {
            pausePreview()
        }
    }
    
    func toggleYouTube() {
        expandYouTube.toggle()
    }
    
    // MARK: - Audio Logic
    func playPreview(url: String?) {
        guard let urlString = url,
              let url = URL(string: urlString) else { return }
        
        player = AVPlayer(url: url)
        player?.play()
        isPlaying = true
    }
    
    func pausePreview() {
        player?.pause()
        isPlaying = false
    }
}
