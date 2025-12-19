//
//  AppEnviroment.swift
//  Vibely
//
//  Created by Mohd Saif on 13/11/25.
//

import Foundation
import FirebaseFirestore

final class AppEnvironment {
    static let shared = AppEnvironment()  // global reference
    
    let cloudinaryService: CloudinaryService
    let firestore: Firestore
    
    private init() {
        self.cloudinaryService = CloudinaryService()
        self.firestore = Firestore.firestore()
    }
}
