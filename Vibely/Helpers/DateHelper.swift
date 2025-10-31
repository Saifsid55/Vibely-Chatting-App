//
//  DateHelper.swift
//  Vibely
//
//  Created by Mohd Saif on 31/10/25.
//
import Foundation

extension Date {
    func chatFormatted() -> String {
        let formatter = DateFormatter()
        let hoursPassed = Date().timeIntervalSince(self) / 3600
        if hoursPassed < 24 {
            formatter.timeStyle = .short
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
        }
        return formatter.string(from: self)
    }
}
