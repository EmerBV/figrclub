//
//  LegalDocumentService.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

// MARK: - Legal Document Service Protocol
protocol LegalDocumentServiceProtocol: Sendable {
    func fetchLegalDocument(_ request: LegalDocumentRequest) async throws -> LegalDocumentResponse
    func fetchTermsOfService(countryCode: String) async throws -> LegalDocumentResponse
    func fetchPrivacyPolicy(countryCode: String) async throws -> LegalDocumentResponse
}

// MARK: - Legal Document Service
final class LegalDocumentService: LegalDocumentServiceProtocol {
    
    // MARK: - Properties
    private let networkDispatcher: NetworkDispatcherProtocol
    private let cache: LegalDocumentCache
    
    // MARK: - Initialization
    init(networkDispatcher: NetworkDispatcherProtocol) {
        self.networkDispatcher = networkDispatcher
        self.cache = LegalDocumentCache()
        Logger.debug("🔧 LegalDocumentService: Initialized with DTO mappers")
    }
    
    // MARK: - LegalDocumentServiceProtocol Implementation
    func fetchLegalDocument(_ request: LegalDocumentRequest) async throws -> LegalDocumentResponse {
        // Convert domain model to DTO
        let requestDTO = LegalDocumentRequestDTO(
            documentType: request.documentType.rawValue,
            countryCode: request.countryCode
        )
        
        // Check cache first
        let cacheKey = "\(request.documentType.rawValue)_\(request.countryCode)"
        if let cachedResponse = cache.getDocument(for: cacheKey) {
            Logger.info("📄 LegalDocumentService: Returning cached document for \(request.documentType.displayName)")
            return cachedResponse
        }
        
        let endpoint = LegalDocumentEndpoints.getLegalDocument(request: requestDTO)
        Logger.info("📄 LegalDocumentService: Fetching \(request.documentType.displayName) for country: \(request.countryCode)")
        
        do {
            let responseDTO: LegalDocumentResponseDTO = try await networkDispatcher.dispatch(endpoint)
            
            let response = LegalDocumentMappers.toLegalDocumentResponse(from: responseDTO)
            
            Logger.info("✅ LegalDocumentService: Successfully fetched \(request.documentType.displayName)")
            cache.setDocument(response, for: cacheKey)
            return response
        } catch {
            Logger.error("❌ LegalDocumentService: Failed to fetch \(request.documentType.displayName) - Error: \(error)")
            throw LegalDocumentError.networkError(error.localizedDescription)
        }
    }
    
    func fetchTermsOfService(countryCode: String) async throws -> LegalDocumentResponse {
        let request = LegalDocumentRequest.termsOfService(for: countryCode)
        return try await fetchLegalDocument(request)
    }
    
    func fetchPrivacyPolicy(countryCode: String) async throws -> LegalDocumentResponse {
        let request = LegalDocumentRequest.privacyPolicy(for: countryCode)
        return try await fetchLegalDocument(request)
    }
}

// MARK: - Legal Document Cache
private final class LegalDocumentCache {
    private var documents: [String: CachedDocument] = [:]
    private let cacheTimeout: TimeInterval = 3600 // 1 hora
    
    private struct CachedDocument {
        let response: LegalDocumentResponse
        let timestamp: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 3600 // 1 hora
        }
    }
    
    func getDocument(for key: String) -> LegalDocumentResponse? {
        guard let cached = documents[key], !cached.isExpired else {
            documents.removeValue(forKey: key)
            return nil
        }
        return cached.response
    }
    
    func setDocument(_ response: LegalDocumentResponse, for key: String) {
        documents[key] = CachedDocument(response: response, timestamp: Date())
    }
    
    func clearCache() {
        documents.removeAll()
    }
}
