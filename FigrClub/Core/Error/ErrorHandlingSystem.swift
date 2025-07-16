//
//  ErrorHandlingSystem.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Error Category
enum ErrorCategory: String, CaseIterable {
    case network = "network"
    case authentication = "auth"
    case validation = "validation"
    case storage = "storage"
    case system = "system"
    case user = "user"
    
    var icon: String {
        switch self {
        case .network:
            return "wifi.slash"
        case .authentication:
            return "person.crop.circle.badge.xmark"
        case .validation:
            return "exclamationmark.triangle"
        case .storage:
            return "externaldrive.badge.xmark"
        case .system:
            return "gear.badge.xmark"
        case .user:
            return "person.badge.minus"
        }
    }
    
    var color: Color {
        switch self {
        case .network:
            return .orange
        case .authentication:
            return .red
        case .validation:
            return .yellow
        case .storage:
            return .purple
        case .system:
            return .gray
        case .user:
            return .blue
        }
    }
}

// MARK: - Error Severity
enum ErrorSeverity: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    var description: String {
        switch self {
        case .low:
            return "Información"
        case .medium:
            return "Advertencia"
        case .high:
            return "Error"
        case .critical:
            return "Crítico"
        }
    }
    
    var color: Color {
        switch self {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        case .critical:
            return .purple
        }
    }
}

// MARK: - App Error Model
struct AppErrorModel: Error, Identifiable, Equatable {
    let id = UUID()
    let category: ErrorCategory
    let severity: ErrorSeverity
    let title: String
    let message: String
    let timestamp: Date
    let isRetryable: Bool
    let shouldLog: Bool
    let underlyingError: Error?
    
    init(
        category: ErrorCategory,
        severity: ErrorSeverity,
        title: String,
        message: String,
        isRetryable: Bool = false,
        shouldLog: Bool = true,
        underlyingError: Error? = nil
    ) {
        self.category = category
        self.severity = severity
        self.title = title
        self.message = message
        self.timestamp = Date()
        self.isRetryable = isRetryable
        self.shouldLog = shouldLog
        self.underlyingError = underlyingError
    }
    
    static func == (lhs: AppErrorModel, rhs: AppErrorModel) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Error Handler Protocol
protocol ErrorHandlerProtocol: ObservableObject {
    var currentError: AppErrorModel? { get }
    var showError: Bool { get }
    var errorHistory: [AppErrorModel] { get }
    
    func handle(_ error: Error)
    func handle(_ appError: AppErrorModel)
    func dismiss()
    func retry() async
    func clearHistory()
}

// MARK: - Global Error Handler
@MainActor
final class GlobalErrorHandler: ErrorHandlerProtocol {
    @Published var currentError: AppErrorModel?
    @Published var showError = false
    @Published var errorHistory: [AppErrorModel] = []
    
    private var retryAction: (() async -> Void)?
    private let maxHistorySize = 50
    
    // MARK: - Error Handling
    
    func handle(_ error: Error) {
        let appError = mapToAppError(error)
        handle(appError)
    }
    
    func handle(_ appError: AppErrorModel) {
        // Log error if needed
        if appError.shouldLog {
            logError(appError)
        }
        
        // Add to history
        addToHistory(appError)
        
        // Show error if severity is medium or higher
        if appError.severity.rawValue >= ErrorSeverity.medium.rawValue {
            currentError = appError
            showError = true
            
            // Auto-dismiss for low severity errors
            if appError.severity == .medium {
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    await MainActor.run {
                        self.dismiss()
                    }
                }
            }
        }
    }
    
    func dismiss() {
        currentError = nil
        showError = false
        retryAction = nil
    }
    
    func retry() async {
        dismiss()
        await retryAction?()
    }
    
    func setRetryAction(_ action: @escaping () async -> Void) {
        retryAction = action
    }
    
    func clearHistory() {
        errorHistory.removeAll()
    }
    
    // MARK: - Error Mapping
    
    private func mapToAppError(_ error: Error) -> AppErrorModel {
        if let networkError = error as? NetworkError {
            return mapNetworkError(networkError)
        }
        
        if let appError = error as? AppErrorModel {
            return appError
        }
        
        if let authError = error as? AuthError {
            return mapAuthError(authError)
        }
        
        // Default mapping
        return AppErrorModel(
            category: .system,
            severity: .medium,
            title: "Error Inesperado",
            message: error.localizedDescription,
            isRetryable: false,
            underlyingError: error
        )
    }
    
    private func mapNetworkError(_ networkError: NetworkError) -> AppErrorModel {
        let category: ErrorCategory = .network
        let isRetryable = networkError.isRetryable
        
        let (severity, title) = networkErrorSeverityAndTitle(networkError)
        let message = enhanceErrorMessage(networkError)
        
        return AppErrorModel(
            category: category,
            severity: severity,
            title: title,
            message: message,
            isRetryable: isRetryable,
            underlyingError: networkError
        )
    }
    
    private func enhanceErrorMessage(_ networkError: NetworkError) -> String {
        switch networkError {
        case .badRequest(let apiError):
            // Check if this is a password validation error
            if let apiError = apiError,
               apiError.message.lowercased().contains("validación") &&
               (apiError.message.lowercased().contains("password") || 
                apiError.message.lowercased().contains("contraseña")) {
                return """
                Tu contraseña no cumple con los requisitos de seguridad.
                
                Debe contener:
                • Al menos 8 caracteres
                • Al menos una letra
                • Al menos un número  
                • Al menos un carácter especial (!@#$%^&*)
                • Sin espacios
                """
            }
            return apiError?.message ?? "Solicitud incorrecta"
        default:
            return networkError.userFriendlyMessage
        }
    }
    
    private func networkErrorSeverityAndTitle(_ networkError: NetworkError) -> (ErrorSeverity, String) {
        switch networkError {
        case .noInternetConnection:
            return (.high, "Sin Conexión")
        case .timeout:
            return (.medium, "Tiempo Agotado")
        case .unauthorized:
            return (.high, "No Autorizado")
        case .serverError:
            return (.high, "Error del Servidor")
        case .badRequest:
            return (.medium, "Solicitud Incorrecta")
        case .rateLimited:
            return (.medium, "Demasiadas Solicitudes")
        case .maintenance:
            return (.critical, "Mantenimiento")
        default:
            return (.medium, "Error de Red")
        }
    }
    
    private func mapAuthError(_ authError: AuthError) -> AppErrorModel {
        return AppErrorModel(
            category: .authentication,
            severity: .high,
            title: "Error de Autenticación",
            message: authError.localizedDescription,
            isRetryable: true,
            underlyingError: authError
        )
    }
    
    // MARK: - Helper Methods
    
    private func addToHistory(_ error: AppErrorModel) {
        errorHistory.insert(error, at: 0)
        
        // Maintain history size
        if errorHistory.count > maxHistorySize {
            errorHistory = Array(errorHistory.prefix(maxHistorySize))
        }
    }
    
    private func logError(_ error: AppErrorModel) {
        let logLevel: LogLevel = error.severity == .critical ? .error : .warning
        
        Logger.log(
            logLevel,
            message: """
            [ErrorHandler] \(error.category.rawValue.uppercased()) ERROR:
            Title: \(error.title)
            Message: \(error.message)
            Severity: \(error.severity.description)
            Retryable: \(error.isRetryable)
            Timestamp: \(error.timestamp)
            Underlying: \(error.underlyingError?.localizedDescription ?? "None")
            """
        )
        
        // Send to analytics/crash reporting if needed
        if error.severity == .critical {
            // TODO: Send to crash reporting service
        }
    }
}

// MARK: - Error Factory
final class ErrorFactory {
    
    static func createValidationError(_ message: String) -> AppErrorModel {
        return AppErrorModel(
            category: .validation,
            severity: .medium,
            title: "Error de Validación",
            message: message,
            isRetryable: false
        )
    }
    
    static func createNetworkUnavailableError() -> AppErrorModel {
        return AppErrorModel(
            category: .network,
            severity: .high,
            title: "Red No Disponible",
            message: "Verifica tu conexión a internet e intenta nuevamente",
            isRetryable: true
        )
    }
    
    static func createAuthenticationError(_ message: String? = nil) -> AppErrorModel {
        return AppErrorModel(
            category: .authentication,
            severity: .high,
            title: "Error de Autenticación",
            message: message ?? "Tu sesión ha expirado. Por favor, inicia sesión nuevamente",
            isRetryable: true
        )
    }
    
    static func createStorageError(_ message: String) -> AppErrorModel {
        return AppErrorModel(
            category: .storage,
            severity: .medium,
            title: "Error de Almacenamiento",
            message: message,
            isRetryable: false
        )
    }
    
    static func createSystemError(_ message: String) -> AppErrorModel {
        return AppErrorModel(
            category: .system,
            severity: .medium,
            title: "Error del Sistema",
            message: message,
            isRetryable: false
        )
    }
}

// MARK: - Error Alert View Modifier
struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var errorHandler: GlobalErrorHandler
    
    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.currentError?.title ?? "Error",
                isPresented: $errorHandler.showError,
                presenting: errorHandler.currentError
            ) { error in
                // Dismiss button
                Button("OK") {
                    errorHandler.dismiss()
                }
                
                // Retry button (if retryable)
                if error.isRetryable {
                    Button("Reintentar") {
                        Task {
                            await errorHandler.retry()
                        }
                    }
                }
            } message: { error in
                VStack(alignment: .leading, spacing: 8) {
                    Label(error.message, systemImage: error.category.icon)
                    
                    if error.severity == .critical {
                        Text("Por favor, contacta al soporte técnico si el problema persiste.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
    }
}

// MARK: - View Extension
extension View {
    func errorAlert(errorHandler: GlobalErrorHandler) -> some View {
        modifier(ErrorAlertModifier(errorHandler: errorHandler))
    }
} 