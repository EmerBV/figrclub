//
//  Date+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import SwiftUI
import Combine

extension Date {
    /// Returns a human-readable relative time string
    var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Returns a short relative time string
    var shortTimeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Formats date for display
    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
}

extension Optional where Wrapped == String {
    /// Returns true if the optional string is nil or empty
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}
