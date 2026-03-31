import SwiftUI

@MainActor
protocol FindUsersViewModelProtocol: ObservableObject {
    var users: [AppUser] { get }
    func loadUsers()
}

@MainActor
final class FindUsersViewModel: FindUsersViewModelProtocol {
    @Published private(set) var users: [AppUser] = []

    private let loadUsersUseCase: LoadMockUsersUseCase

    init(loadUsersUseCase: LoadMockUsersUseCase = LoadMockUsersUseCase()) {
        self.loadUsersUseCase = loadUsersUseCase
        loadUsers()
    }

    func loadUsers() {
        users = loadUsersUseCase.execute()
    }
}
