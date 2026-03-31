//
//  FindModel.swift
//  Vibely
//
//  Created by Mohd Saif on 19/12/25.
//

// UserModel.swift

import Foundation

enum Gender: String {
    case male = "Male"
    case female = "Female"
    case other = "Other"
}

struct AppUser: Identifiable {
    let id = UUID()
    let name: String
    let profession: String
    let age: Int
    let gender: Gender
    let imageURL: String
}
