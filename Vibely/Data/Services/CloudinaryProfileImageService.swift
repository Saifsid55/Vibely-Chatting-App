//
//  CloudinaryProfileImageService.swift
//  Vibely
//
//  Created by Muhammad Saif on 22/01/26.
//
import UIKit

enum ProfileImageServiceError: Error {
    case invalidImageData
    case hashGenerationFailed
    case sameImage
}

final class CloudinaryProfileImageService: ProfileImageService {
    
    private let cloudinary: CloudinaryService
    
    init(cloudinary: CloudinaryService) {
        self.cloudinary = cloudinary
    }
    
    func uploadImage(
        data: Data,
        type: ProfileImageType,
        existingHash: String?
    ) async throws -> (url: String, hash: String) {
        
        // 1️⃣ Convert Data → UIImage
        guard let image = UIImage(data: data) else {
            throw ProfileImageServiceError.invalidImageData
        }
        
        // 2️⃣ Generate hash (MUST succeed)
        guard let hash = image.sha256() else {
            throw ProfileImageServiceError.hashGenerationFailed
        }
        
        // 3️⃣ Skip upload if same image
        if hash == existingHash {
            throw ProfileImageServiceError.sameImage
        }
        
        // 4️⃣ Upload
        let uploadType: CloudinaryUploadType =
        (type == .profile) ? .profile : .cover
        
        let url = try await cloudinary.upload(
            image: image,
            type: uploadType
        )
        
        return (url: url, hash: hash)
    }
}
