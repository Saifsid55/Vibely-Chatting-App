//
//  TickStatusView.swift
//  Vibely
//
//  Created by Mohd Saif on 23/10/25.
//

import SwiftUI

struct TickStatusView: View {
    let status: MessageStatus
    let shouldAnimate: Bool
    
    @State private var animateTrim = false
    
    var body: some View {
        ZStack {
            // MARK: - Circle (show only for delivered/seen)
            if status != .sent {
                Circle()
                    .trim(from: 0.20, to: animateTrim ? 1.10 : 0.08)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .foregroundColor(statusColor)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 16, height: 16)
            }
            
            // MARK: - Tick mark (always visible)
            CheckmarkShape()
                .trim(from: 0, to: animateTrim ? 1 : 0)
                .stroke(statusColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: 12, height: 12)
                .offset(x: 1.0, y: -1.5)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: animateTrim)
        }
        .frame(width: 20, height: 20)
        .onAppear {
            // ✅ Always trigger animation or instant state
            if shouldAnimate {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateTrim = true
                }
            } else {
                animateTrim = true
            }
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .sent: return .gray
        case .delivered: return .gray
        case .seen: return .green
        }
    }
}

// MARK: - Custom Checkmark Shape
struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 2, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX - 1, y: rect.maxY - 3))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 2))
        return path
    }
}
