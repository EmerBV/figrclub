//
//  ViewState.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 11/7/25.
//

import Foundation
import SwiftUI

// MARK: - ViewState for UI Management
enum ViewState<T> {
    case idle
    case loading
    case success(T)
    case failure(NetworkError)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var error: NetworkError? {
        if case .failure(let error) = self { return error }
        return nil
    }
    
    var data: T? {
        if case .success(let data) = self { return data }
        return nil
    }
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

// MARK: - Simple Error Handler
@MainActor
final class ErrorHandler: ObservableObject {
    @Published var currentError: NetworkError?
    @Published var showError = false
    
    func handle(_ error: Error) {
        let networkError = NetworkError.from(error)
        currentError = networkError
        showError = true
        
        Logger.error("🔥 ErrorHandler: [\(networkError.category)] \(networkError.userFriendlyMessage)")
        
        // Opcional: Haptic feedback para errores
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func dismiss() {
        currentError = nil
        showError = false
    }
}

// MARK: - Error Alert View Modifier
struct ErrorAlert: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler
    let retryAction: (() async -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: $errorHandler.showError,
                presenting: errorHandler.currentError
            ) { error in
                Button("OK") {
                    errorHandler.dismiss()
                }
                
                if error.isRetryable, let retryAction = retryAction {
                    Button("Reintentar") {
                        errorHandler.dismiss()
                        Task { await retryAction() }
                    }
                }
            } message: { error in
                Label(error.userFriendlyMessage, systemImage: error.iconName)
            }
    }
}

extension View {
    func errorAlert(
        errorHandler: ErrorHandler,
        retryAction: (() async -> Void)? = nil
    ) -> some View {
        modifier(ErrorAlert(errorHandler: errorHandler, retryAction: retryAction))
    }
}
