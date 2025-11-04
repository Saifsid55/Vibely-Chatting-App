//
//  MoodMeter.swift
//  Vibely
//
//  Created by Mohd Saif on 05/11/25.
//

import SwiftUI

struct MoodMeterView: View {
    var mood: String
    @State private var isChanging = false

    // MARK: - Mood Logic
    private var moodLevel: Double {
        switch mood {
        case "😊", "😄", "😁", "😍": return 1.0     // very happy
        case "🙂", "😌", "😅": return 0.75          // happy
        case "😐", "😕": return 0.5                 // neutral
        case "😢", "😭", "😞": return 0.25          // sad
        case "😡", "😠", "🤬": return 0.1           // angry
        default: return 0.5                         // fallback neutral
        }
    }

    private var moodColor: Color {
        switch moodLevel {
        case 0.75...1.0: return .green
        case 0.5..<0.75: return .yellow
        case 0.25..<0.5: return .orange
        default: return .red
        }
    }

    // MARK: - View
    var body: some View {
        ZStack {
            // Background arc (gray)
            ArcShape(progress: 1.0)
                .stroke(
                    Color.gray.opacity(0.25),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 30, height: 16)
                .rotationEffect(.degrees(180))

            // Foreground arc (colored progress)
            ArcShape(progress: moodLevel)
                .stroke(
                    moodColor,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 30, height: 16)
                .rotationEffect(.degrees(180))
                .animation(.easeInOut(duration: 0.5), value: moodLevel)

            // Center face (emoji)
            Text(mood)
                .font(.system(size: 13))
                .offset(y: 2)
        }
        .frame(width: 30, height: 22)
        .scaleEffect(isChanging ? 1.15 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: isChanging)
        .onChange(of: mood) { _, _ in
            isChanging = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isChanging = false
            }
        }
    }
}

// MARK: - Arc Shape with Progress Support
struct ArcShape: Shape {
    var progress: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Arc from 200° to -20° (like a curved smile)
        let startAngle: Double = 0
        let endAngle: Double = 180
        let totalAngle = startAngle - endAngle
        let currentEndAngle = startAngle - totalAngle * progress

        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(currentEndAngle),
            clockwise: false
        )

        return path
    }

    var animatableData: Double {
        get { progress }
        set { self.progress = newValue }
    }
}
