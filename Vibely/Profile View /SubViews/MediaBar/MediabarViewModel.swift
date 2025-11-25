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
    @Published var spotifyRotation: Double = 0
    @Published var youtubeRotation: Double = 0
    
    // MARK: - Selected Media
    
    @Published var spotifySong: SpotifySong? = nil       // Selected Spotify Song
    @Published var youtubeVideo: YouTubeVideo? = nil     // Selected YouTube Video
    @Published var isPlaying = false
    
    private var player: AVPlayer?
    
    
    // MARK: - Mock Data (Remove Later)
    
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
    
    // MARK: - Adding Media
    
    func addSpotifySong(_ song: SpotifySong) {
        self.spotifySong = song
    }
    
    func addYouTubeVideo(_ video: YouTubeVideo) {
        self.youtubeVideo = video
    }
    
    // MARK: - Clearing Media
    
    func clearSpotify() {
        self.spotifySong = nil
    }
    
    func clearYouTube() {
        self.youtubeVideo = nil
    }
    
    // MARK: - Expand / Collapse Logic
    /*
     func toggleSpotify() {
     withAnimation {
     expandSpotify.toggle()
     if expandSpotify {
     //                expandYouTube = false
     } else {
     pausePreview()
     }
     }
     }
     
     func toggleYouTube() {
     withAnimation {
     expandYouTube.toggle()
     if expandYouTube {
     //                expandSpotify = false
     pausePreview()
     }
     }
     }
     */
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
    
    func toggleSpotify() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if expandSpotify == false {
                // expanding → rotate clockwise
                spotifyRotation += 360
            } else {
                // collapsing → rotate anticlockwise
                spotifyRotation -= 360
            }
            expandSpotify.toggle()
        }
    }
    
    func toggleYouTube() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if expandYouTube == false {
                // expanding → rotate clockwise
                youtubeRotation += 360
            } else {
                // collapsing → rotate anticlockwise
                youtubeRotation -= 360
            }
            expandYouTube.toggle()
        }
    }
    
}
