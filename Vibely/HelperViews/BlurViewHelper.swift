//
//  BlurViewHelper.swift
//  Vibely
//
//  Created by Mohd Saif on 12/11/25.
//

import UIKit
import SwiftUI
// Create a custom blur view using UIVisualEffectView
struct CustomBlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    var intensity: CGFloat // 0.0 to 1.0
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.alpha = intensity
        return blurView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
        uiView.alpha = intensity
    }
}

// Custom ViewModifier for easy blur application
struct CustomBlurModifier: ViewModifier {
    var style: UIBlurEffect.Style
    var intensity: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(CustomBlurView(style: style, intensity: intensity))
    }
}

// Extension for convenient usage
extension View {
    func customBlur(style: UIBlurEffect.Style = .systemUltraThinMaterialDark, intensity: CGFloat = 1.0) -> some View {
        self.modifier(CustomBlurModifier(style: style, intensity: intensity))
    }
}
