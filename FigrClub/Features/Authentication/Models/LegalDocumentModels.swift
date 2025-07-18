//
//  LegalDocumentModels.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

// MARK: - Legal Document Type
enum LegalDocumentType: String, CaseIterable, Codable {
    case termsOfService = "TERMS_OF_SERVICE"
    case privacyPolicy = "PRIVACY_POLICY"
    
    var displayName: String {
        switch self {
        case .termsOfService:
            return "Términos y Condiciones"
        case .privacyPolicy:
            return "Política de Privacidad"
        }
    }
    
    var endpoint: String {
        return "/legal/international/documents/\(rawValue)/country"
    }
}

// MARK: - Legal Document Request (Domain Model)
struct LegalDocumentRequest {
    let documentType: LegalDocumentType
    let countryCode: String
    
    var endpoint: String {
        return "\(documentType.endpoint)/\(countryCode)"
    }
    
    // MARK: - Factory Methods
    static func termsOfService(for countryCode: String) -> LegalDocumentRequest {
        return LegalDocumentRequest(documentType: .termsOfService, countryCode: countryCode)
    }
    
    static func privacyPolicy(for countryCode: String) -> LegalDocumentRequest {
        return LegalDocumentRequest(documentType: .privacyPolicy, countryCode: countryCode)
    }
}

// MARK: - Legal Document Domain Model
struct LegalDocument {
    let id: Int
    let documentType: LegalDocumentType
    let title: String
    let slug: String
    let content: String
    let summary: String
    let version: String
    let effectiveDate: String
    let publishedAt: String
    let language: String
    let country: String
    let requiresAcceptance: Bool
    let displayOrder: Int
    let documentUrl: String
    
    // MARK: - Computed Properties
    var formattedEffectiveDate: Date? {
        return ISO8601DateFormatter().date(from: effectiveDate)
    }
    
    var formattedPublishedDate: Date? {
        return ISO8601DateFormatter().date(from: publishedAt)
    }
    
    var htmlContent: String {
        return content
    }
    
    var isCurrentVersion: Bool {
        guard let effectiveDate = formattedEffectiveDate else { return false }
        return effectiveDate <= Date()
    }
}

// MARK: - Legal Document Response Type Aliases
typealias LegalDocumentResponse = ApiResponse<LegalDocument>

// MARK: - Legal Document Error
enum LegalDocumentError: Error, LocalizedError {
    case documentNotFound
    case unsupportedLanguage
    case unsupportedCountry
    case invalidDocumentType
    case networkError(String)
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .documentNotFound:
            return "Documento legal no encontrado"
        case .unsupportedLanguage:
            return "Idioma no soportado"
        case .unsupportedCountry:
            return "País no soportado"
        case .invalidDocumentType:
            return "Tipo de documento inválido"
        case .networkError(let message):
            return "Error de red: \(message)"
        case .decodingError(let message):
            return "Error al procesar el documento: \(message)"
        }
    }
}
