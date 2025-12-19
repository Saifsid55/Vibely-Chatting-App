//
//  FIndViewModel.swift
//  Vibely
//
//  Created by Mohd Saif on 19/12/25.
//


import SwiftUI

@MainActor
final class FindUsersViewModel: ObservableObject {
    
    @Published var users: [AppUser] = []
    
    init() {
        loadMockUsers()
    }
    
    func loadMockUsers() {
        users = [
            AppUser(
                name: "Aarav Sharma",
                profession: "iOS Developer",
                age: 26,
                gender: .male,
                imageURL: "https://i.pravatar.cc/300?img=12"
            ),
            AppUser(
                name: "Ananya Singh",
                profession: "UI Designer",
                age: 24,
                gender: .female,
                imageURL: "https://i.pravatar.cc/300?img=47"
            ),
            AppUser(
                name: "Rohit Verma",
                profession: "Product Manager",
                age: 29,
                gender: .male,
                imageURL: "https://i.pravatar.cc/300?img=32"
            ),
            AppUser(
                name: "Neha Gupta",
                profession: "Content Creator",
                age: 25,
                gender: .female,
                imageURL: "https://i.pravatar.cc/300?img=56"
            ),

            // MARK: Muslim Names
            AppUser(
                name: "Ayaan Khan",
                profession: "Backend Engineer",
                age: 27,
                gender: .male,
                imageURL: "https://i.pravatar.cc/300?img=14"
            ),
            AppUser(
                name: "Zara Ahmed",
                profession: "Fashion Blogger",
                age: 23,
                gender: .female,
                imageURL: "https://i.pravatar.cc/300?img=48"
            ),
            AppUser(
                name: "Mohammad Faizan",
                profession: "Android Developer",
                age: 28,
                gender: .male,
                imageURL: "https://i.pravatar.cc/300?img=33"
            ),
            AppUser(
                name: "Aisha",
                profession: "Digital Marketer",
                age: 24,
                gender: .female,
                imageURL: "https://i.pravatar.cc/300?img=55"
            ),
            AppUser(
                name: "Arman Ali",
                profession: "Startup Founder",
                age: 31,
                gender: .male,
                imageURL: "https://i.pravatar.cc/300?img=18"
            ),
            AppUser(
                name: "Sana Noor",
                profession: "Psychology Student",
                age: 22,
                gender: .female,
                imageURL: "https://i.pravatar.cc/300?img=52"
            ),
            AppUser(
                name: "Imran Sheikh",
                profession: "Data Analyst",
                age: 30,
                gender: .male,
                imageURL: "https://i.pravatar.cc/300?img=21"
            ),
            AppUser(
                name: "Fatima Rizvi",
                profession: "UX Researcher",
                age: 26,
                gender: .female,
                imageURL: "https://i.pravatar.cc/300?img=49"
            ),
            AppUser(
                name: "Saad Malik",
                profession: "DevOps Engineer",
                age: 29,
                gender: .male,
                imageURL: "https://i.pravatar.cc/300?img=26"
            ),
            AppUser(
                name: "Noor Jahan",
                profession: "Interior Designer",
                age: 27,
                gender: .female,
                imageURL: "https://i.pravatar.cc/300?img=53"
            )
        ]
    }

}
