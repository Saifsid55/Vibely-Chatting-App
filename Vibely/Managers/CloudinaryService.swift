//
//  CloudinaryService.swift
//  Vibely
//
//  Created by Mohd Saif on 13/11/25.
//

import Foundation
import Cloudinary
import UIKit
import FirebaseFunctions
import FirebaseAuth

enum CloudinaryUploadType: String {
    case profile = "profile"
    case cover = "cover"
    case gallery = "gallery"
}

final class CloudinaryService {
    // MARK: - Private Config
    private let cloudName = "dlfgwr1k8"
    private let uploadPreset = "find_unsigned"
    private let folder = "find_uploads"
    private lazy var functions = Functions.functions(region: "us-central1")
    private let cloudinary: CLDCloudinary
    
    // MARK: - Init
    init() {
        let config = CLDConfiguration(cloudName: cloudName, secure: true)
        self.cloudinary = CLDCloudinary(configuration: config)
    }
    
    // MARK: - Upload Image (Async)
    func upload(image: UIImage, type: CloudinaryUploadType) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "CloudinaryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let params = CLDUploadRequestParams()
                .setUploadPreset(uploadPreset)
                .setFolder("\(folder)/\(type.rawValue)")
            cloudinary.createUploader().upload(data: data, uploadPreset: uploadPreset, params: params, progress: { progress in
                print("📤 Upload progress: \(progress.fractionCompleted * 100)%")
            }) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let secureUrl = result?.secureUrl {
                    continuation.resume(returning: secureUrl)
                } else {
                    continuation.resume(throwing: NSError(domain: "CloudinaryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Upload failed"]))
                }
            }
        }
    }
    
    func deleteImageViaFirebase(publicId: String) async throws {
        guard Auth.auth().currentUser != nil else {
            print("❌ No Firebase auth user available to call Cloud Function")
            throw NSError(domain: "CloudinaryService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("🗑️ Attempting to delete publicId:", publicId)

        // Build callable - Firebase SDK automatically handles auth
        let callable = functions.httpsCallable("deleteCloudinaryImage")
        
        do {
            let result = try await callable.call(["publicId": publicId])
            
            print("🗑️ Successfully deleted from Cloudinary via Firebase")
            if let data = result.data as? [String: Any] {
                print("📦 Response:", data)
            }
        } catch let error as NSError {
            print("❌ Firebase delete failed with code:", error.code)
            print("❌ Error domain:", error.domain)
            print("❌ Error description:", error.localizedDescription)
            
            // Extract all available error information
            for (key, value) in error.userInfo {
                print("❌ UserInfo[\(key)]:", value)
            }
            
            // Check for function-specific details
            if let details = error.userInfo["details"] {
                print("❌ Function error details:", details)
            }
            
            if let message = error.userInfo["message"] {
                print("❌ Function error message:", message)
            }
            
            throw error
        }
    }

    // MARK: - Extract public_id from Cloudinary URL
    // Fixed version that handles Cloudinary URLs properly
    func extractPublicId(from urlString: String) -> String? {
        print("🔗 Processing URL:", urlString)
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL string:", urlString)
            return nil
        }
        
        // Example URL: https://res.cloudinary.com/dlfgwr1k8/image/upload/v1234567890/find_uploads/cover/abc123.jpg
        // We need: find_uploads/cover/abc123
        
        let path = url.path
        print("🔍 Full path:", path)
        
        let components = path.components(separatedBy: "/").filter { !$0.isEmpty }
        print("🔍 Path components:", components)
        
        // Find index of "upload" component
        guard let uploadIndex = components.firstIndex(of: "upload") else {
            print("❌ Could not find 'upload' in path")
            return nil
        }
        
        // Find index of component starting with "v" followed by digits (version)
        // It should be right after "upload"
        let versionIndex = uploadIndex + 1
        guard versionIndex < components.count,
              components[versionIndex].hasPrefix("v"),
              components[versionIndex].dropFirst().allSatisfy({ $0.isNumber }) else {
            print("❌ Could not find version after 'upload'")
            return nil
        }
        
        // Public ID is everything after the version, joined with "/"
        let publicIdStartIndex = versionIndex + 1
        guard publicIdStartIndex < components.count else {
            print("❌ No components after version")
            return nil
        }
        
        let publicIdComponents = components[publicIdStartIndex...]
        
        // Join and remove file extension
        var publicId = publicIdComponents.joined(separator: "/")
        
        // Remove file extension (.jpg, .png, etc.)
        if let lastDotIndex = publicId.lastIndex(of: ".") {
            publicId = String(publicId[..<lastDotIndex])
        }
        
        print("✅ Extracted publicId:", publicId)
        return publicId
    }
}
