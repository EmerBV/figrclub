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
    case getTermsOfService(request: LegalDocumentRequestDTO)
    case getPrivacyPolicy(request: LegalDocumentRequestDTO)
    
    var path: String {
        switch self {
        case .getLegalDocument(request: let request):
            return request.endpoint
        case .getTermsOfService(request: let request):
            return request.endpoint
        case .getPrivacyPolicy(request: let request):
            return request.endpoint
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
        case .getLegalDocument(let request):
            return try? request.toDictionary()
        case .getTermsOfService(let request):
            return try? request.toDictionary()
        case .getPrivacyPolicy(let request):
            return try? request.toDictionary()
        }
    }
    
    /*
    /// Get legal document by type and country
    static func getLegalDocument(request: LegalDocumentRequest) -> APIEndpoint {
        return APIEndpoint(
            path: request.endpoint,
            method: .GET,
            headers: [
                "Accept": "application/json",
                "Content-Type": "application/json"
            ],
            queryItems: nil,
            body: nil,
            requiresAuth: false,
            cachePolicy: .useProtocolCachePolicy,
            timeout: 30.0,
            retryPolicy: .default
        )
    }
    
    /// Get Terms of Service
    static func getTermsOfService(countryCode: String) -> APIEndpoint {
        let request = LegalDocumentRequest.termsOfService(for: countryCode)
        return getLegalDocument(request: request)
    }
    
    /// Get Privacy Policy
    static func getPrivacyPolicy(countryCode: String) -> APIEndpoint {
        let request = LegalDocumentRequest.privacyPolicy(for: countryCode)
        return getLegalDocument(request: request)
    }
     */
}
