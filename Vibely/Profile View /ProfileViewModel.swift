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
    
    // Photo picker state
    @Published var showCoverPicker = false
    @Published var selectedCoverItem: PhotosPickerItem? {
        didSet { Task { await handleCoverSelection() } }
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
    
    // MARK: - Generic firestore field updater
    func updateProfileField(field: String, value: Any) async {
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
    
    // MARK: - Upload Cover Photo (Cloudinary)
    /// Accepts raw image data (from PhotosPicker) — converts to UIImage then uploads
    func uploadCoverPhoto(imageData: Data) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }
        
        guard let uiImage = UIImage(data: imageData) else {
            self.errorMessage = "Invalid image data"
            return
        }
        guard let newHash = uiImage.sha256() else {
            self.errorMessage = "Failed to generate image hash"
            return
        }
        
        // 👇 If current profile already has same image hash → skip upload
        if let oldHash = profile?.coverPhotoHash, oldHash == newHash {
            print("⚠️ Same cover photo selected — skipping upload.")
            return
        }
        
        // MARK: - Delete old cover photo (if exists)
        if let oldURL = profile?.coverPhotoURL,
           let publicId = cloudinary.extractPublicId(from: oldURL) {
            do {
                try await cloudinary.deleteImageViaFirebase(publicId: publicId)
                print("🗑️ Old cover image deleted")
            } catch {
                print("⚠️ Failed to delete old image:", error.localizedDescription)
            }
        }
        
        // MARK: - Upload new image
        do {
            let secureURL = try await cloudinary.upload(image: uiImage, type: .cover)
            
            try await db.collection("users").document(uid).updateData([
                "coverPhotoURL": secureURL,
                "coverPhotoHash": newHash,
                "updatedAt": FieldValue.serverTimestamp()
            ])
            
            await loadProfile(for: uid)
            print("✅ Cover photo uploaded: \(secureURL)")
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ uploadCoverPhoto error:", error.localizedDescription)
        }
    }
    
    // MARK: - Upload Profile Photo (Cloudinary)
    func uploadProfilePhoto(imageData: Data) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }
        
        guard let uiImage = UIImage(data: imageData) else {
            self.errorMessage = "Invalid image data"
            return
        }
        
        do {
            let secureURL = try await cloudinary.upload(image: uiImage, type: .profile)
            try await db.collection("users").document(uid).updateData([
                "photoURL": secureURL,
                "updatedAt": FieldValue.serverTimestamp()
            ])
            await loadProfile(for: uid)
            print("✅ Profile photo uploaded: \(secureURL)")
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ uploadProfilePhoto error:", error.localizedDescription)
        }
    }
    
    // MARK: - Add Photo to Collection (Cloudinary + Firestore array)
    func addPhotoToCollection(imageData: Data) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }
        
        guard let uiImage = UIImage(data: imageData) else {
            self.errorMessage = "Invalid image data"
            return
        }
        
        do {
            let secureURL = try await cloudinary.upload(image: uiImage, type: .gallery)
            try await db.collection("users").document(uid).updateData([
                "collectionPhotos": FieldValue.arrayUnion([secureURL]),
                "updatedAt": FieldValue.serverTimestamp()
            ])
            await loadProfile(for: uid)
            print("✅ Gallery photo added: \(secureURL)")
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ addPhotoToCollection error:", error.localizedDescription)
        }
    }
    
    // MARK: - Handle PhotosPicker selection
    private func handleCoverSelection() async {
        guard let item = selectedCoverItem else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                print("📸 Selected image data: \(data.count) bytes")
                await uploadCoverPhoto(imageData: data)            // <-- now matches signature
            } else {
                self.errorMessage = "Failed to read selected image"
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ PhotosPicker load error:", error.localizedDescription)
        }
    }
}
