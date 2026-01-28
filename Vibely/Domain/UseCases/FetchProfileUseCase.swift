//
//  FetchProfileUseCase.swift
//  Vibely
//
//  Created by Muhammad Saif on 22/01/26.
//
import Foundation

final class FetchProfileUseCase {
    private let repository: ProfileRepository

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    func execute(userId: String) async throws -> UserProfile {
        try await repository.fetchProfile(userId: userId)
    }
}
