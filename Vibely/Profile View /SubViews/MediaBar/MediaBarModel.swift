//
//  MediaBarModel.swift
//  Vibely
//
//  Created by Mohd Saif on 25/11/25.
//
import Foundation

protocol MediaItem: Identifiable, Codable {
    var id: String { get }
    var title: String { get }
    var thumbnailURL: String? { get }
    var externalURL: String { get }  // link to open
}


struct SpotifySong: MediaItem, Codable {
    let id: String              // Spotify track ID
    let title: String           // Song title
    let artist: String          // Artist name
    let thumbnailURL: String?   // Album art
    let previewURL: String?     // 30 sec preview audio URL
    let externalURL: String     // Spotify deep link
    
    // Optional metadata
    let durationMS: Int?
    let albumName: String?
    
    init(
        id: String,
        title: String,
        artist: String,
        thumbnailURL: String? = nil,
        previewURL: String? = nil,
        externalURL: String,
        durationMS: Int? = nil,
        albumName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.thumbnailURL = thumbnailURL
        self.previewURL = previewURL
        self.externalURL = externalURL
        self.durationMS = durationMS
        self.albumName = albumName
    }
}


struct YouTubeVideo: MediaItem, Codable {
    let id: String              // YouTube video ID
    let title: String
    let thumbnailURL: String?   // Max resolution thumbnail
    let externalURL: String     // YouTube link
    
    // Optional metadata
    let channelName: String?
    let duration: String?       // formatted "10:12"
    
    init(
        id: String,
        title: String,
        thumbnailURL: String? = nil,
        externalURL: String,
        channelName: String? = nil,
        duration: String? = nil
    ) {
        self.id = id
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.externalURL = externalURL
        self.channelName = channelName
        self.duration = duration
    }
}


enum MediaType: String, Codable {
    case spotify
    case youtube
}

struct MediaWrapper: Identifiable, Codable {
    let id = UUID().uuidString
    let type: MediaType
    let spotify: SpotifySong?
    let youtube: YouTubeVideo?
}
