//
//  LegalDocumentEndpoints.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

// MARK: - Legal Document Endpoints
enum LegalDocumentEndpoints: APIEndpoint {
    case getLegalDocument(request: LegalDocumentRequestDTO)
    case getTermsOfService(countryCode: String)
    case getPrivacyPolicy(countryCode: String)
    
    var path: String {
        switch self {
        case .getLegalDocument(let request):
            return "/legal/international/documents/\(request.documentType)/country/\(request.countryCode)"
        case .getTermsOfService(let countryCode):
            return "/legal/international/documents/TERMS_OF_SERVICE/country/\(countryCode)"
        case .getPrivacyPolicy(let countryCode):
            return "/legal/international/documents/PRIVACY_POLICY/country/\(countryCode)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getLegalDocument, .getTermsOfService, .getPrivacyPolicy:
            return .GET
        }
    }
    
    var body: [String: Any]? {
        switch self {
        case .getLegalDocument, .getTermsOfService, .getPrivacyPolicy:
            return nil
        }
    }
    
    var requiresAuth: Bool {
        switch self {
        case .getLegalDocument, .getTermsOfService, .getPrivacyPolicy:
            return false
        }
    }
}
