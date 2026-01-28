//
//  ProfileImageService.swift
//  Vibely
//
//  Created by Muhammad Saif on 22/01/26.
//
import Foundation

protocol ProfileImageService {
    func uploadImage(
        data: Data,
        type: ProfileImageType,
        existingHash: String?
    ) async throws -> (url: String, hash: String)
}
