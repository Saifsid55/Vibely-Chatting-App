//
//  Views.swift
//  Vibely
//
//  Created by Mohd Saif on 08/11/25.
//
import Foundation
import SwiftUI

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

extension View {
    func onAppearOrChange<T: Equatable>(
        of value: T,
        perform action: @escaping () -> Void
    ) -> some View {
        self.onAppear(perform: action)
            .onChange(of: value) { _, _ in action() }
    }
}

// Rounded corners helper
struct RoundedCorner: Shape {
    var radius: CGFloat = 16
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
