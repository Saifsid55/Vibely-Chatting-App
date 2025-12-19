//
//  HapticManager.swift
//  Vibely
//
//  Created by Mohd Saif on 25/11/25.
//

import UIKit

final class HapticManager {
    
    static let shared = HapticManager()
    private init() {}
    
    // MARK: - Light Tap
    func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Medium Tap
    func mediumTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Heavy Tap
    func heavyTap() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Selection Change (good for toggles)
    func selectionChange() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Success / Warning / Error
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
