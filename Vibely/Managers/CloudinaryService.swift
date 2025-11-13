//
//  CloudinaryService.swift
//  Vibely
//
//  Created by Mohd Saif on 13/11/25.
//

import Foundation
import Cloudinary
import UIKit

enum CloudinaryUploadType: String {
    case profile = "profile"
    case cover = "cover"
    case gallery = "gallery"
}

final class CloudinaryService {
    // MARK: - Private Config
    private let cloudName = "dlfgwr1k8" // 🔹 from your Cloudinary Dashboard
    private let uploadPreset = "find_unsigned" // 🔹 your unsigned upload preset
    private let folder = "find_uploads"
    
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
}
