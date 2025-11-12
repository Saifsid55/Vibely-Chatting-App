//
//  Helper.swift
//  Vibely
//
//  Created by Mohd Saif on 09/10/25.
//

import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r, g, b, a: CGFloat
        if hexSanitized.count == 8 {
            r = CGFloat((rgb >> 24) & 0xFF) / 255
            g = CGFloat((rgb >> 16) & 0xFF) / 255
            b = CGFloat((rgb >> 8) & 0xFF) / 255
            a = CGFloat(rgb & 0xFF) / 255
        } else {
            r = CGFloat((rgb >> 16) & 0xFF) / 255
            g = CGFloat((rgb >> 8) & 0xFF) / 255
            b = CGFloat(rgb & 0xFF) / 255
            a = 1.0
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

extension LinearGradient {
    enum Direction {
        case leftToRight
        case topToBottom
        
        var startPoint: UnitPoint {
            switch self {
            case .leftToRight: return .leading
            case .topToBottom: return .top
            }
        }
        
        var endPoint: UnitPoint {
            switch self {
            case .leftToRight: return .trailing
            case .topToBottom: return .bottom
            }
        }
    }
    
    init(hexColors: [String], direction: Direction = .leftToRight) {
        let colors = hexColors.compactMap { Color(hex: $0) }
        self.init(
            gradient: Gradient(colors: colors),
            startPoint: direction.startPoint,
            endPoint: direction.endPoint
        )
    }
}

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r, g, b, a: Double
        switch hexSanitized.count {
        case 8:
            r = Double((rgb >> 24) & 0xFF) / 255
            g = Double((rgb >> 16) & 0xFF) / 255
            b = Double((rgb >> 8) & 0xFF) / 255
            a = Double(rgb & 0xFF) / 255
        case 6:
            r = Double((rgb >> 16) & 0xFF) / 255
            g = Double((rgb >> 8) & 0xFF) / 255
            b = Double(rgb & 0xFF) / 255
            a = 1.0
        default:
            r = 1; g = 1; b = 1; a = 1 // fallback white
        }
        
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

extension Gradient.Stop {
    init(hex: String, location: CGFloat) {
        self.init(color: Color(hex: hex) ?? .clear, location: location)
    }
}


extension View {
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
}
