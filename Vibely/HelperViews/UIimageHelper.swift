//
//  UIimageHelper.swift
//  Vibely
//
//  Created by Mohd Saif on 14/11/25.
//
import CryptoKit
import Foundation
import UIKit

extension UIImage {
    func sha256() -> String? {
        guard let data = self.jpegData(compressionQuality: 1.0) else { return nil }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
