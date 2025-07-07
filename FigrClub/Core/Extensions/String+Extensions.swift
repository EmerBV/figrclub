//
//  String+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import SwiftUI

extension String {
    /// Validates if the string is a valid email format
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Validates if the string is a valid username
    var isValidUsername: Bool {
        let usernameRegex = "^[a-zA-Z0-9_-]{3,30}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: self)
    }
    
    /// Returns the first letter capitalized
    var firstLetterCapitalized: String {
        guard !isEmpty else { return self }
        return String(prefix(1)).uppercased()
    }
    
    /// Returns initials from full name
    var initials: String {
        return self
            .components(separatedBy: .whitespacesAndNewlines)
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()
    }
    
    /// Truncates string to specified length with ellipsis
    func truncated(to length: Int) -> String {
        guard count > length else { return self }
        return String(prefix(length)) + "..."
    }
    
    /// Removes whitespaces and newlines
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func formatPostDate() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: self) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .short
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }
        
        // Fallback: intentar formato simple
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let date = fallbackFormatter.date(from: self) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .short
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }
        
        // Si no se puede parsear, devolver como está
        return self
    }
}
