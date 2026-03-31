//
//  SimpleLiquidWave.swift
//  Vibely
//
//  Created by Mohd Saif on 25/10/25.
//

import SwiftUI

struct SimpleLiquidWave: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.white.opacity(0.15), location: 0.0),
                .init(color: Color.clear, location: 0.4),
                .init(color: Color.white.opacity(0.1), location: 0.7),
                .init(color: Color.clear, location: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .scaleEffect(1.3)
        .rotationEffect(.radians(phase))
        .blur(radius: 20)
        .onAppear {
            withAnimation(
                .linear(duration: 10.0)
                .repeatForever(autoreverses: false)
            ) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Blur View
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
