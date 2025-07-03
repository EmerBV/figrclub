//
//  LegalModels.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 3/7/25.
//

import Foundation

// MARK: - Legal Acceptance
struct LegalAcceptance: Codable {
    let type: LegalDocumentType
    let acceptedAt: Date
    let ipAddress: String?
    let version: String
    
    init(type: LegalDocumentType, version: String, ipAddress: String? = nil) {
        self.type = type
        self.acceptedAt = Date()
        self.ipAddress = ipAddress
        self.version = version
    }
}

// MARK: - Legal Document Type
enum LegalDocumentType: String, Codable {
    case termsOfService = "TERMS_OF_SERVICE"
    case privacyPolicy = "PRIVACY_POLICY"
    case cookiePolicy = "COOKIE_POLICY"
    case ageConsent = "AGE_CONSENT"
}

// MARK: - Consent
struct Consent: Codable {
    let type: ConsentType
    let granted: Bool
    let grantedAt: Date?
    let revokedAt: Date?
    
    init(type: ConsentType, granted: Bool) {
        self.type = type
        self.granted = granted
        self.grantedAt = granted ? Date() : nil
        self.revokedAt = granted ? nil : Date()
    }
}

// MARK: - Consent Type
enum ConsentType: String, Codable {
    case marketing = "MARKETING"
    case analytics = "ANALYTICS"
    case personalizedAds = "PERSONALIZED_ADS"
    case dataSharing = "DATA_SHARING"
    case pushNotifications = "PUSH_NOTIFICATIONS"
    case emailNotifications = "EMAIL_NOTIFICATIONS"
}
