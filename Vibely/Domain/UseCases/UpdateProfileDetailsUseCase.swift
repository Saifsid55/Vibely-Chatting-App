//
//  UpdateProfileDetailsUseCase.swift
//  Vibely
//
//  Created by Muhammad Saif on 22/01/26.
//
import Foundation

final class UpdateProfileDetailsUseCase {
    private let repository: ProfileRepository

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    func execute(userId: String, details: ProfileUpdateDetails) async throws {
        try await repository.updateProfileDetails(userId: userId, details: details)
    }
}
