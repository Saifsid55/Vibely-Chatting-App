//
//  SlidingText.swift
//  Vibely
//
//  Created by Mohd Saif on 25/11/25.
//

import SwiftUI


struct SlidingText: View {
    let text: String
    let speed: Double = 0.03
    
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Measure container
                Color.clear
                    .onAppear {
                        containerWidth = geo.size.width
                    }
                    .onChange(of: geo.size.width) { _, newValue in
                        containerWidth = newValue
                        restartAnimation()
                    }
                
                // Scrolling text
                HStack(spacing: 40) {
                    Text(text)
                        .lineLimit(1)
                        .fixedSize()
                    
                    if textWidth > containerWidth {
                        Text(text)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
                .background(
                    GeometryReader { textGeo in
                        Color.clear
                            .onAppear {
                                textWidth = textGeo.size.width
                                startAnimation()
                            }
                            .onChange(of: textGeo.size.width) { _, newValue in
                                textWidth = newValue
                                restartAnimation()
                            }
                    }
                )
                .offset(x: offset)
            }
        }
        .frame(height: 20)
        .clipped()
        .onChange(of: text) { _, _ in
            restartAnimation()
        }
    }
    
    func startAnimation() {
        guard textWidth > containerWidth else { return }
        
        let totalDistance = textWidth + 40 // 40 is the spacing
        let duration = totalDistance * speed
        
        withAnimation(
            Animation.linear(duration: duration)
                .repeatForever(autoreverses: false)
        ) {
            offset = -totalDistance
        }
    }
    
    func restartAnimation() {
        offset = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            startAnimation()
        }
    }
}
