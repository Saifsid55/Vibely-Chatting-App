//
//  AuthViewModel.swift
//  Vibely
//
//  Created by Mohd Saif on 02/10/25.
//

import FirebaseAuth
import Combine

final class AuthViewModel: ObservableObject {
    @Published var user: User? // your User model or Auth.auth().currentUser
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { _, firebaseUser in
            self.user = firebaseUser
        }
    }

    func signUp(email: String, password: String, displayName: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let err = error { completion(err); return }
            guard let uid = result?.user.uid else { completion(nil); return }
            // Store profile in Firestore (see next section)
            completion(nil)
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, err in completion(err) }
    }

    func signInAnonymously(completion: @escaping (Error?) -> Void) {
        Auth.auth().signInAnonymously { _, err in completion(err) }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
