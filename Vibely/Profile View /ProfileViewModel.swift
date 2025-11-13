//
//  ProfileViewModel.swift
//  Vibely
//
//  Created by Mohd Saif on 13/11/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI
import _PhotosUI_SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfileModel?
    @Published var isCurrentUserProfile = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Photo Picker State
    @Published var showCoverPicker = false
    @Published var selectedCoverItem: PhotosPickerItem? {
        didSet { Task { await handleCoverSelection() } }
    }
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // MARK: - Load Profile
    func loadProfile(for userId: String) async {
        do {
            isLoading = true
            let doc = try await db.collection("users").document(userId).getDocument()
            if let profile = try? doc.data(as: UserProfileModel.self) {
                await MainActor.run {
                    self.profile = profile
                    self.isCurrentUserProfile = (Auth.auth().currentUser?.uid == userId)
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Profile not found"
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Load Current User
    func loadCurrentUserProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        await loadProfile(for: uid)
    }
    
    // MARK: - Update Profile Field
    func updateProfileField(field: String, value: Any) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await db.collection("users").document(uid).updateData([
                field: value,
                "updatedAt": FieldValue.serverTimestamp()
            ])
            await loadProfile(for: uid)
        } catch {
            await MainActor.run { self.errorMessage = error.localizedDescription }
        }
    }
    
    // MARK: - Upload Generic Image
    private func uploadImage(imageData: Data, path: String, fieldToUpdate: String) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            await MainActor.run {
                self.errorMessage = "User not authenticated"
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        print("🔄 Starting upload for user: \(uid)")
        print("🔄 Path: users/\(uid)/\(path).jpg")
        print("🔄 Image size: \(imageData.count) bytes")
        
        let ref = storage.reference().child("users/\(uid)/\(path).jpg")
        
        do {
            // Step 1: Upload with metadata
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            print("⬆️ Uploading image...")
            let uploadResult = try await ref.putDataAsync(imageData, metadata: metadata)
            print("✅ Upload completed: \(uploadResult)")
            
            // Step 2: Wait for Firebase to process (critical!)
            print("⏳ Waiting for Firebase to process...")
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Step 3: Retry logic for getting download URL
            var downloadURL: URL?
            var retryCount = 0
            let maxRetries = 3
            
            while downloadURL == nil && retryCount < maxRetries {
                do {
                    print("🔗 Attempt \(retryCount + 1) to fetch download URL...")
                    downloadURL = try await ref.downloadURL()
                    print("✅ Download URL obtained: \(downloadURL!.absoluteString)")
                } catch {
                    retryCount += 1
                    if retryCount < maxRetries {
                        print("⚠️ Retry \(retryCount) failed, waiting 1 second...")
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                    } else {
                        throw error
                    }
                }
            }
            
            guard let finalDownloadURL = downloadURL else {
                throw NSError(domain: "ProfileViewModel", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL after \(maxRetries) attempts"])
            }
            
            // Step 4: Add cache busting
            let finalURL = finalDownloadURL.absoluteString + "?t=\(Int(Date().timeIntervalSince1970))"
            
            // Step 5: Update Firestore
            print("💾 Updating Firestore field: \(fieldToUpdate)")
            try await db.collection("users").document(uid).updateData([
                fieldToUpdate: finalURL,
                "updatedAt": FieldValue.serverTimestamp()
            ])
            print("✅ Firestore updated successfully")
            
            // Step 6: Reload profile
            print("🔄 Reloading profile...")
            await loadProfile(for: uid)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            print("✅ Upload complete!")
            
        } catch let error as NSError {
            print("❌ Upload failed:")
            print("   Domain: \(error.domain)")
            print("   Code: \(error.code)")
            print("   Description: \(error.localizedDescription)")
            
            await MainActor.run {
                self.isLoading = false
                
                // Better error messages
                if error.domain == "FIRStorageErrorDomain" {
                    switch error.code {
                    case 17002:
                        self.errorMessage = "Upload failed: File not found after upload. Please check Firebase Storage rules and try again."
                    case 17001:
                        self.errorMessage = "Upload failed: Unauthorized. Please check Firebase Storage rules."
                    case -13010:
                        self.errorMessage = "Upload failed: Network error. Please check your internet connection."
                    default:
                        self.errorMessage = "Upload failed: \(error.localizedDescription)"
                    }
                } else {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Upload Cover Photo (Shortcut)
    func uploadCoverPhoto(imageData: Data) async {
        await uploadImage(imageData: imageData,
                          path: "cover/cover",
                          fieldToUpdate: "coverPhotoURL")
    }
    
    // MARK: - Upload Profile Photo (Shortcut)
    func uploadProfilePhoto(imageData: Data) async {
        await uploadImage(imageData: imageData,
                          path: "profile/profile",
                          fieldToUpdate: "photoURL")
    }
    
    // MARK: - Add New Photo to Array (Gallery)
    func addPhotoToArray(imageData: Data) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let photoId = UUID().uuidString
        let ref = storage.reference().child("users/\(uid)/photos/\(photoId).jpg")
        
        do {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            _ = try await ref.putDataAsync(imageData, metadata: metadata)
            
            // Wait for processing
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            let downloadURL = try await ref.downloadURL()
            try await db.collection("users").document(uid).updateData([
                "photos": FieldValue.arrayUnion([downloadURL.absoluteString]),
                "updatedAt": FieldValue.serverTimestamp()
            ])
            await loadProfile(for: uid)
        } catch {
            await MainActor.run { self.errorMessage = error.localizedDescription }
        }
    }
    
    // MARK: - Handle PhotosPicker Selection
    private func handleCoverSelection() async {
        guard let item = selectedCoverItem else { return }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            print("📸 Loading image from PhotosPicker...")
            if let data = try await item.loadTransferable(type: Data.self) {
                print("✅ Image loaded: \(data.count) bytes")
                await uploadCoverPhoto(imageData: data)
            } else {
                print("❌ Failed to load image data")
                await MainActor.run {
                    self.errorMessage = "Failed to load image"
                    self.isLoading = false
                }
            }
        } catch {
            print("❌ PhotosPicker error: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
