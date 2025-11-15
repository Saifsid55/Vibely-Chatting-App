//
//  ProfileViewModel.swift
//  Vibely
//
//  Created by Mohd Saif on 13/11/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import _PhotosUI_SwiftUI
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfileModel?
    @Published var isCurrentUserProfile = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Picker States
    @Published var tempCoverImageData: Data?
    @Published var showCoverPicker = false
    @Published var selectedCoverItem: PhotosPickerItem? {
        didSet { Task { await handlePickerSelection(for: .cover) } }
    }
    
    @Published var tempProfileImageData: Data?
    @Published var showProfilePicker = false
    @Published var selectedProfileItem: PhotosPickerItem? {
        didSet { Task { await handlePickerSelection(for: .profile) } }
    }
    
    private let cloudinary: CloudinaryService
    private let db: Firestore
    
    init(
        db: Firestore = AppEnvironment.shared.firestore,
        cloudinary: CloudinaryService = AppEnvironment.shared.cloudinaryService
    ) {
        self.db = db
        self.cloudinary = cloudinary
    }
    
    // MARK: - Load Profile
    func loadProfile(for userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            if let profile = try? doc.data(as: UserProfileModel.self) {
                self.profile = profile
                self.isCurrentUserProfile = (Auth.auth().currentUser?.uid == userId)
            } else {
                self.errorMessage = "Profile not found"
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func loadCurrentUserProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        await loadProfile(for: uid)
    }
    
    // MARK: - Generic Firestore Update
    func updateField(_ field: String, value: Any) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await db.collection("users").document(uid).updateData([
                field: value,
                "updatedAt": FieldValue.serverTimestamp()
            ])
            await loadProfile(for: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    
    // ============================================================
    // MARK: - UNIFIED IMAGE HANDLER
    // ============================================================
    
    enum UploadType {
        case cover
        case profile
        case gallery
        
        var firestoreField: String {
            switch self {
            case .cover: return "coverPhotoURL"
            case .profile: return "photoURL"
            case .gallery: return "collectionPhotos"
            }
        }
        
        var hashField: String {
            switch self {
            case .cover: return "coverPhotoHash"
            case .profile: return "photoHash"
            case .gallery: return ""
            }
        }
        
        var imageType: CloudinaryUploadType {
            switch self {
            case .cover: return .cover
            case .profile: return .profile
            case .gallery: return .gallery
            }
        }
    }
    
    
    /// 🔥 One function handles upload for Cover + Profile + Gallery
    func uploadImage(_ data: Data, type: UploadType) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let uiImage = UIImage(data: data) else {
            errorMessage = "Invalid image data"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // MARK: - Generate Hash (skip for gallery)
        var newHash: String?
        if type != .gallery {
            newHash = uiImage.sha256()
            if newHash == nil {
                errorMessage = "Failed to generate image hash"
                return
            }
        }
        
        // MARK: - Skip if same image (cover/profile)
        if type == .cover,
           let old = profile?.coverPhotoHash, old == newHash {
            print("⚠️ Same cover photo — skipping upload")
            return
        }
        
        if type == .profile,
           let old = profile?.profilePhotoHash, old == newHash {
            print("⚠️ Same profile photo — skipping upload")
            return
        }
        
        
        // MARK: - Delete old image (except gallery)
        if type != .gallery {
            let oldURL = (type == .cover) ? profile?.coverPhotoURL : profile?.photoURL
            
            if let url = oldURL,
               let publicId = cloudinary.extractPublicId(from: url) {
                do {
                    try await cloudinary.deleteImageViaFirebase(publicId: publicId)
                } catch {
                    print("⚠️ Failed deleting old image:", error.localizedDescription)
                }
            }
        }
        
        // MARK: - Upload new image
        do {
            let secureURL = try await cloudinary.upload(image: uiImage, type: type.imageType)
            
            var updateData: [String: Any] = [
                type.firestoreField: (type == .gallery) ?
                FieldValue.arrayUnion([secureURL]) : secureURL,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            if type != .gallery, let hash = newHash {
                updateData[type.hashField] = hash
            }
            
            try await db.collection("users").document(uid).updateData(updateData)
            await loadProfile(for: uid)
            
            print("✅ Uploaded \(type) → \(secureURL)")
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    
    // ============================================================
    // MARK: - UNIFIED PICKER HANDLER
    // ============================================================
    
    private func handlePickerSelection(for type: UploadType) async {
        let item: PhotosPickerItem?
        
        switch type {
        case .cover: item = selectedCoverItem
        case .profile: item = selectedProfileItem
        case .gallery: item = nil
        }
        
        guard let pickerItem = item else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let data = try await pickerItem.loadTransferable(type: Data.self) {
                
                switch type {
                case .cover: tempCoverImageData = data
                case .profile: tempProfileImageData = data
                default: break
                }
                
            } else {
                errorMessage = "Failed to read image"
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func updateProfileDetails(
        name: String,
        bio: String,
        location: String,
        gender: String,
        age: String,
        profession: String
    ) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .updateData([
                    "displayName": name,
                    "bio": bio,
                    "location": location,
                    "gender": gender,
                    "age": age,
                    "profession": profession
                ])
            
            // 🔥 Update local model
            self.profile?.displayName = name
            self.profile?.bio = bio
            self.profile?.location = location
            self.profile?.gender = gender
            self.profile?.age = age
            self.profile?.profession = profession
            
        } catch {
            print("❌ Failed updating user profile:", error.localizedDescription)
        }
    }
}
