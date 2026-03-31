//
//  Untitled.swift
//  Vibely
//
//  Created by Mohd Saif on 11/11/25.
//
import Foundation
import SwiftUI

struct RoundedTopArcShape: Shape {
    let profileRadius: CGFloat
    let padding: CGFloat
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Arc setup
        let arcRadius = profileRadius + padding
        let centerX = rect.midX
        let arcCenter = CGPoint(x: centerX, y: 0)
        
        // Start at top-left corner
        path.move(to: CGPoint(x: 0, y: 0))
        
        // Left top edge → arc start
        path.addLine(to: CGPoint(x: centerX - arcRadius, y: 0))
        
        // Concave arc cutout (U-shaped)
        path.addArc(center: arcCenter,
                    radius: arcRadius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(0),
                    clockwise: true)
        
        // Top-right edge → continue
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        
        // Right side down (rounded bottom-right corner)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY),
                          control: CGPoint(x: rect.maxX, y: rect.maxY))
        
        // Bottom line → left side (rounded bottom-left corner)
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: 0, y: rect.maxY - cornerRadius),
                          control: CGPoint(x: 0, y: rect.maxY))
        
        path.closeSubpath()
        return path
    }
}
