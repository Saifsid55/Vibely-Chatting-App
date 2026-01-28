//
//  UploadProfileImageUseCase.swift
//  Vibely
//
//  Created by Muhammad Saif on 22/01/26.
//
import Foundation

final class UploadProfileImageUseCase {
    private let imageService: ProfileImageService
    private let repository: ProfileRepository

    init(
        imageService: ProfileImageService,
        repository: ProfileRepository
    ) {
        self.imageService = imageService
        self.repository = repository
    }

    func execute(
        userId: String,
        imageData: Data,
        type: ProfileImageType,
        existingHash: String?
    ) async throws {
        let result = try await imageService.uploadImage(
            data: imageData,
            type: type,
            existingHash: existingHash
        )

        try await repository.updateImage(
            userId: userId,
            type: type,
            imageURL: result.url,
            imageHash: result.hash
        )
    }
}

