//
//  BaseViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 2/7/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
open class BaseViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Private Properties
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupErrorHandling()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Error Handling
    private func setupErrorHandling() {
        $errorMessage
            .map { $0 != nil }
            .assign(to: &$showError)
    }
    
    func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        // Auto-hide error after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            hideError()
        }
    }
    
    func hideError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Loading State Management
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    // MARK: - Async Operation Helpers
    func executeWithLoading<T>(
        _ operation: @escaping () async throws -> T,
        onSuccess: @escaping (T) -> Void = { _ in },
        onError: @escaping (Error) -> Void = { _ in }
    ) async {
        setLoading(true)
        
        do {
            let result = try await operation()
            onSuccess(result)
            hideError()
        } catch {
            handleError(error)
            onError(error)
        }
        
        setLoading(false)
    }
    
    func executeWithLoadingMore<T>(
        _ operation: @escaping () async throws -> T,
        onSuccess: @escaping (T) -> Void = { _ in },
        onError: @escaping (Error) -> Void = { _ in }
    ) async {
        // Similar to executeWithLoading but for pagination
        do {
            let result = try await operation()
            onSuccess(result)
        } catch {
            handleError(error)
            onError(error)
        }
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        let errorHandler = DefaultErrorHandler()
        let message = errorHandler.getUserFriendlyMessage(for: error)
        showErrorMessage(message)
        
        // Log error
        Logger.shared.error("ViewModel error", error: error, category: "viewmodel")
    }
}

// MARK: - Paginated ViewModel
@MainActor
open class PaginatedViewModel<T: Identifiable>: BaseViewModel {
    
    // MARK: - Published Properties
    @Published var items: [T] = []
    @Published var isLoadingMore = false
    @Published var hasMoreData = true
    
    // MARK: - Pagination Properties
    var currentPage = 0
    var pageSize = 20
    var totalPages = 0
    var totalElements = 0
    
    // MARK: - Abstract Methods (Must be overridden)
    open func loadFirstPage() async {
        fatalError("loadFirstPage() must be overridden")
    }
    
    open func loadNextPage() async {
        fatalError("loadNextPage() must be overridden")
    }
    
    // MARK: - Public Methods
    func refresh() async {
        currentPage = 0
        hasMoreData = true
        await loadFirstPage()
    }
    
    func loadMore() async {
        guard !isLoadingMore && hasMoreData else { return }
        
        isLoadingMore = true
        await loadNextPage()
        isLoadingMore = false
    }
    
    // MARK: - Helper Methods
    func replaceItems<U: Codable>(_ newItems: [T], from response: PaginatedResponse<U>) {
        items = newItems
        updatePaginationData(from: response)
    }
    
    func appendItems<U: Codable>(_ newItems: [T], from response: PaginatedResponse<U>) {
        items.append(contentsOf: newItems)
        updatePaginationData(from: response)
    }
    
    private func updatePaginationData<U: Codable>(from response: PaginatedResponse<U>) {
        currentPage = response.currentPage
        totalPages = response.totalPages
        totalElements = response.totalElements
        hasMoreData = currentPage < totalPages - 1
    }
}

// MARK: - Searchable ViewModel
@MainActor
open class SearchableViewModel<T: Identifiable>: PaginatedViewModel<T> {
    
    // MARK: - Published Properties
    @Published var searchText = ""
    @Published var isSearching = false
    
    // MARK: - Private Properties
    private var searchCancellable: AnyCancellable?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupSearch()
    }
    
    // MARK: - Search Setup
    private func setupSearch() {
        searchCancellable = $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task {
                    await self?.performSearch()
                }
            }
    }
    
    private func performSearch() async {
        isSearching = true
        await refresh()
        isSearching = false
    }
    
    func clearSearch() {
        searchText = ""
    }
}

// MARK: - Form ViewModel
@MainActor
open class FormViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    @Published var isFormValid = false
    @Published var validationErrors: [String: String] = [:]
    
    // MARK: - Validation
    func setValidationError(for field: String, message: String?) {
        if let message = message {
            validationErrors[field] = message
        } else {
            validationErrors.removeValue(forKey: field)
        }
        
        updateFormValidation()
    }
    
    func clearValidationErrors() {
        validationErrors.removeAll()
        updateFormValidation()
    }
    
    private func updateFormValidation() {
        isFormValid = validationErrors.isEmpty
    }
    
    func getValidationError(for field: String) -> String? {
        return validationErrors[field]
    }
    
    func hasValidationError(for field: String) -> Bool {
        return validationErrors[field] != nil
    }
}

// MARK: - Validation State
enum ValidationState {
    case idle
    case valid
    case invalid(String)
    
    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .invalid(let message) = self {
            return message
        }
        return nil
    }
}

// MARK: - Supporting Models
struct PaginatedResponse<T: Codable>: Codable {
    let content: [T]
    let totalElements: Int
    let totalPages: Int
    let currentPage: Int
    let size: Int
    let numberOfElements: Int
    let first: Bool
    let last: Bool
    let empty: Bool
}

// MARK: - Publisher Extensions for Async/Await
extension AnyPublisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = self
                .first()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                        cancellable?.cancel()
                    }
                )
        }
    }
}

// MARK: - Default Error Handler
final class DefaultErrorHandler: ErrorHandler {
    
    func handle(_ error: Error) -> ErrorRecoveryStrategy {
        if let apiError = error as? APIError {
            return handleAPIError(apiError)
        }
        
        if let urlError = error as? URLError {
            return handleURLError(urlError)
        }
        
        return .showError
    }
    
    func getUserFriendlyMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return getUserFriendlyAPIErrorMessage(apiError)
        }
        
        if let urlError = error as? URLError {
            return getUserFriendlyURLErrorMessage(urlError)
        }
        
        return "Ha ocurrido un error inesperado. Por favor, inténtalo de nuevo."
    }
    
    private func handleAPIError(_ error: APIError) -> ErrorRecoveryStrategy {
        switch error.statusCode {
        case 401:
            return .refreshTokenAndRetry
        case 500...599:
            return .retry(maxAttempts: 3, delay: 2.0)
        case 400...499:
            return .showError
        default:
            return .retry(maxAttempts: 2, delay: 1.0)
        }
    }
    
    private func handleURLError(_ error: URLError) -> ErrorRecoveryStrategy {
        switch error.code {
        case .networkConnectionLost, .notConnectedToInternet:
            return .retry(maxAttempts: 3, delay: 5.0)
        case .timedOut:
            return .retry(maxAttempts: 2, delay: 3.0)
        default:
            return .showError
        }
    }
    
    private func getUserFriendlyAPIErrorMessage(_ error: APIError) -> String {
        switch error.statusCode {
        case 400:
            return "Los datos enviados no son válidos. Por favor, revisa la información."
        case 401:
            return "Tu sesión ha expirado. Por favor, inicia sesión nuevamente."
        case 403:
            return "No tienes permisos para realizar esta acción."
        case 404:
            return "El recurso solicitado no fue encontrado."
        case 422:
            return "Los datos enviados contienen errores. Por favor, revísalos."
        case 500...599:
            return "Error del servidor. Por favor, inténtalo más tarde."
        default:
            return error.message
        }
    }
    
    private func getUserFriendlyURLErrorMessage(_ error: URLError) -> String {
        switch error.code {
        case .networkConnectionLost:
            return "Se perdió la conexión a internet. Por favor, verifica tu conexión."
        case .notConnectedToInternet:
            return "No hay conexión a internet. Por favor, conecta tu dispositivo."
        case .timedOut:
            return "La conexión tardó demasiado. Por favor, inténtalo de nuevo."
        case .cannotConnectToHost:
            return "No se puede conectar al servidor. Por favor, inténtalo más tarde."
        default:
            return "Error de conexión. Por favor, verifica tu internet e inténtalo de nuevo."
        }
    }
}

// MARK: - Error Handler Protocol
protocol ErrorHandler {
    func handle(_ error: Error) -> ErrorRecoveryStrategy
    func getUserFriendlyMessage(for error: Error) -> String
}

// MARK: - Error Recovery Strategy
enum ErrorRecoveryStrategy {
    case retry(maxAttempts: Int, delay: TimeInterval)
    case refreshTokenAndRetry
    case showError
    case silent
    case logout
}


