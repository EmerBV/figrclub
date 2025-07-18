//
//  LegalDocumentViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

import Combine

// MARK: - Legal Document View Model
@MainActor
final class LegalDocumentViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var document: LegalDocument?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Properties
    private let documentType: LegalDocumentType
    private let countryCode: String
    private let service: LegalDocumentServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(documentType: LegalDocumentType, countryCode: String) {
        self.documentType = documentType
        self.countryCode = countryCode
        self.service = DependencyInjector.shared.resolve(LegalDocumentServiceProtocol.self)
        
        Logger.info("📄 LegalDocumentViewModel: Initialized for \(documentType.displayName) - \(countryCode)")
    }
    
    // MARK: - Public Methods
    
    func loadDocument() async {
        await performWithLoading {
            try await loadDocumentFromService()
        }
    }
    
    func retryLoading() async {
        await loadDocument()
    }
}

// MARK: - Private Methods
private extension LegalDocumentViewModel {
    
    func loadDocumentFromService() async throws {
        Logger.info("📄 LegalDocumentViewModel: Loading \(documentType.displayName) for \(countryCode)")
        
        let request = LegalDocumentRequest(documentType: documentType, countryCode: countryCode)
        let response = try await service.fetchLegalDocument(request)
        
        // Extract the document from the response
        document = response.data
        errorMessage = nil
        
        Logger.info("✅ LegalDocumentViewModel: Successfully loaded \(documentType.displayName)")
    }
    
    func performWithLoading<T>(_ operation: @escaping () async throws -> T) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await operation()
        } catch let error as LegalDocumentError {
            handleLegalDocumentError(error)
        } catch {
            handleGenericError(error)
        }
        
        isLoading = false
    }
    
    func handleLegalDocumentError(_ error: LegalDocumentError) {
        Logger.error("❌ LegalDocumentViewModel: Legal document error: \(error)")
        
        switch error {
        case .documentNotFound:
            errorMessage = "El documento solicitado no está disponible"
        case .unsupportedLanguage:
            errorMessage = "Este documento no está disponible en tu idioma"
        case .unsupportedCountry:
            errorMessage = "Este documento no está disponible para tu país"
        case .invalidDocumentType:
            errorMessage = "Tipo de documento no válido"
        case .networkError(let message):
            errorMessage = "Error de conexión: \(message)"
        case .decodingError(let message):
            errorMessage = "Error al procesar el documento: \(message)"
        }
    }
    
    func handleGenericError(_ error: Error) {
        Logger.error("❌ LegalDocumentViewModel: Generic error: \(error)")
        errorMessage = "Ha ocurrido un error inesperado. Por favor, inténtalo de nuevo."
    }
}

// MARK: - Country Code Helper
extension LegalDocumentViewModel {
    
    /// Get country code from current locale
    static func getCurrentCountryCode() -> String {
        return Locale.current.region?.identifier ?? "ES"
    }
    
    /// Get language code from current locale
    static func getCurrentLanguageCode() -> String {
        return Locale.current.language.languageCode?.identifier ?? "es"
    }
}

// MARK: - Factory Methods
extension LegalDocumentViewModel {
    
    static func termsOfService(countryCode: String = getCurrentCountryCode()) -> LegalDocumentViewModel {
        return LegalDocumentViewModel(documentType: .termsOfService, countryCode: countryCode)
    }
    
    static func privacyPolicy(countryCode: String = getCurrentCountryCode()) -> LegalDocumentViewModel {
        return LegalDocumentViewModel(documentType: .privacyPolicy, countryCode: countryCode)
    }
}
