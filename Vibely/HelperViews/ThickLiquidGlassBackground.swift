//
//  ThickLiquidGlassBackground.swift
//  Vibely
//
//  Created by Mohd Saif on 25/10/25.
//
import SwiftUI

struct ThickLiquidGlassBackground: View {
    @ObservedObject var motion: MotionManager
    @State private var shimmerMove = false
    
    var body: some View {
        ZStack {
            // Strong frosted base (more opaque)
            BlurView(style: .systemUltraThinMaterialDark)
                .opacity(0.95)
            
            // Solid white tint overlay
            Color.white.opacity(0.15)
                .blendMode(.plusLighter)
            
            // Motion-reactive subtle shine
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.7),
                    Color.clear,
                    Color.white.opacity(0.6)
                ]),
                startPoint: UnitPoint(
                    x: 0.5 + motion.roll * 8,   // increased multiplier
                    y: 0.5 + motion.pitch * 8
                ),
                endPoint: UnitPoint(
                    x: 0.5 - motion.roll * 8,
                    y: 0.5 - motion.pitch * 8
                )
            )
            .blur(radius: 25)
            .blendMode(.screen)
            .opacity(0.4)
            .animation(.interpolatingSpring(stiffness: 50, damping: 8), value: motion.pitch + motion.roll)
            
            
            // Gentle liquid wave (subtle)
            SimpleLiquidWave()
                .blendMode(.overlay)
                .opacity(0.25)
        }
        // THICK WHITE BORDER - Key to matching the reference
        .overlay {
            RoundedRectangle(cornerRadius: 29)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.7),
                            Color.white.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
        }
        // Inner glow effect
        .overlay {
            RoundedRectangle(cornerRadius: 29)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                .blur(radius: 1)
                .padding(2.5)
        }
        // Strong outer glow (creates the thick white halo)
        .shadow(color: Color.white.opacity(0.6), radius: 25, y: 0)
        .shadow(color: Color.white.opacity(0.4), radius: 15, y: 8)
        .shadow(color: Color.white.opacity(0.5), radius: 30, y: -3)
        
        .onDisappear {
            motion.stopUpdate()
        }
    }
}
