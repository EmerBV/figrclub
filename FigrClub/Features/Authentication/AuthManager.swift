//
//  AuthManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation
import Combine

// MARK: - Auth State
enum AuthState: Equatable {
    case loading
    case loggingOut
    case authenticated(User)
    case unauthenticated
    case error(String)
    
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading),
            (.loggingOut, .loggingOut),
            (.unauthenticated, .unauthenticated):
            return true
        case (.authenticated(let user1), .authenticated(let user2)):
            return user1 == user2
        case (.error(let error1), .error(let error2)):
            return error1 == error2
        default:
            return false
        }
    }
}

@MainActor
final class AuthStateManager: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private let authRepository: AuthRepositoryProtocol
    private let tokenManager: TokenManager
    private var cancellables = Set<AnyCancellable>()
    
    private var credentialCheckTimer: Timer?
    
    nonisolated init(authRepository: AuthRepositoryProtocol, tokenManager: TokenManager) {
        self.authRepository = authRepository
        self.tokenManager = tokenManager
        
        Task { @MainActor in
            self.setupCredentialMonitoring()
            await self.checkInitialAuthState()
        }
    }
    
    // MARK: - Public Methods
    
    func login(email: String, password: String) async -> Result<User, Error> {
        // 🔧 FIX: Asegurar que el estado se actualiza en el hilo principal
        await MainActor.run {
            authState = .loading
        }
        
        do {
            let user = try await authRepository.login(email: email, password: password)
            await updateAuthenticatedState(with: user)
            Logger.info("✅ AuthStateManager: Login successful for user: \(user.displayName)")
            return .success(user)
        } catch {
            await updateErrorState(error)
            Logger.error("❌ AuthStateManager: Login failed: \(error)")
            return .failure(error)
        }
    }
    
    func register(email: String, password: String, username: String, fullName: String?) async -> Result<User, Error> {
        // Asegurar que el estado se actualiza en el hilo principal
        await MainActor.run {
            authState = .loading
        }
        
        do {
            let user = try await authRepository.register(
                email: email,
                password: password,
                username: username,
                fullName: fullName
            )
            await updateAuthenticatedState(with: user)
            Logger.info("✅ AuthStateManager: Registration successful for user: \(user.displayName)")
            return .success(user)
        } catch {
            await updateErrorState(error)
            Logger.error("❌ AuthStateManager: Registration failed: \(error)")
            return .failure(error)
        }
    }
    
    func logout() async {
        Logger.info("🚪 AuthStateManager: Starting logout process...")
        
        // Cambiar inmediatamente a estado loading en el hilo principal
        await MainActor.run {
            authState = .loggingOut
        }
        
        do {
            // Ejecutar logout del servidor en paralelo (no bloqueante)
            try await authRepository.logout()
            Logger.info("✅ AuthStateManager: Server logout successful")
        } catch {
            Logger.error("❌ AuthStateManager: Server logout failed: \(error), continuing with local cleanup...")
            // No detener el proceso si falla el logout del servidor
        }
        
        // Limpiar estado local SIEMPRE, sin importar si el servidor falló
        await clearLocalAuthData()
        
        // Actualizar inmediatamente a unauthenticated
        await updateUnauthenticatedState()
        
        Logger.info("✅ AuthStateManager: Logout completed successfully")
    }
    
    func refreshToken() async -> Bool {
        do {
            let user = try await authRepository.refreshToken()
            await updateAuthenticatedState(with: user)
            Logger.info("✅ AuthStateManager: Token refresh successful")
            return true
        } catch {
            await updateUnauthenticatedState()
            Logger.error("❌ AuthStateManager: Token refresh failed: \(error)")
            return false
        }
    }
    
    func getCurrentUser() async -> Result<User, Error> {
        // Verificar credenciales usando el método async
        guard await tokenManager.hasValidCredentials() else {
            let error = AuthError.noUserIdFound
            Logger.error("❌ AuthStateManager: No valid credentials found")
            await updateErrorState(error)
            return .failure(error)
        }
        
        do {
            let user = try await authRepository.getCurrentUser()
            await updateAuthenticatedState(with: user)
            Logger.info("✅ AuthStateManager: Successfully retrieved current user: \(user.displayName) (ID: \(user.id))")
            return .success(user)
        } catch {
            Logger.error("❌ AuthStateManager: Failed to get current user: \(error)")
            
            // Si el error es de autorización, intentar refresh token
            if isAuthorizationError(error) {
                Logger.debug("🔄 AuthStateManager: Attempting token refresh due to authorization error")
                let refreshSuccess = await refreshToken()
                if refreshSuccess {
                    // Retry getting current user after refresh
                    return await getCurrentUser()
                }
            }
            
            await updateErrorState(error)
            return .failure(error)
        }
    }
    
    /// Método para verificar el estado inicial de autenticación
    func checkInitialAuthState() async {
        Logger.info("🔍 AuthStateManager: Checking initial authentication state")
        
        // Mantener estado loading durante la verificación inicial
        await MainActor.run {
            authState = .loading
        }
        
        // Usar método async para verificar credenciales
        guard await tokenManager.hasValidCredentials() else {
            await updateUnauthenticatedState()
            Logger.info("📱 AuthStateManager: No valid authentication found")
            return
        }
        
        // Intentar obtener el usuario actual
        let result = await getCurrentUser()
        switch result {
        case .success(let user):
            await updateAuthenticatedState(with: user)
            Logger.info("✅ AuthStateManager: Initial auth check successful for user: \(user.displayName)")
        case .failure(let error):
            Logger.error("❌ AuthStateManager: Initial auth check failed: \(error)")
            
            // Si falla, intentar refresh token una vez
            Logger.debug("🔄 AuthStateManager: Attempting token refresh on initial check")
            let refreshSuccess = await refreshToken()
            if !refreshSuccess {
                await updateUnauthenticatedState()
            }
        }
    }
    
    /// Método para actualizar la información del usuario
    func updateUser(_ user: User) async {
        currentUser = user
        authState = .authenticated(user)
        isAuthenticated = true
        Logger.info("🔄 AuthStateManager: User updated: \(user.displayName)")
    }
    
    /// Método para forzar un refresh del usuario actual
    func forceRefreshCurrentUser() async -> Result<User, Error> {
        Logger.debug("🔄 AuthStateManager: Force refreshing current user")
        return await getCurrentUser()
    }
    
    /// Método para limpiar datos locales
    private func clearLocalAuthData() async {
        // Limpiar tokens
        await tokenManager.clearTokens()
        
        // Limpiar usuario en memoria
        currentUser = nil
        isAuthenticated = false
        
        Logger.debug("🗑️ AuthStateManager: Local auth data cleared")
    }
    
    private func setupCredentialMonitoring() {
        // Monitor credentials periodically instead of reactive subscriptions
        credentialCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkCredentialsIfAuthenticated()
            }
        }
        
        Logger.debug("🔄 AuthStateManager: Credential monitoring setup completed")
    }
    
    private func checkCredentialsIfAuthenticated() async {
        // Solo verificar si estamos actualmente autenticados
        guard isAuthenticated else { return }
        
        let hasValidCredentials = await tokenManager.hasValidCredentials()
        
        if !hasValidCredentials {
            Logger.warning("⚠️ AuthStateManager: Credentials invalidated, updating auth state")
            await updateUnauthenticatedState()
        }
    }
    
    // MARK: - Private Methods
    
    private func updateAuthenticatedState(with user: User) async {
        await MainActor.run {
            currentUser = user
            authState = .authenticated(user)
            isAuthenticated = true
        }
        Logger.debug("✅ AuthStateManager: Updated to authenticated state for user: \(user.displayName)")
    }
    
    private func updateUnauthenticatedState() async {
        await MainActor.run {
            currentUser = nil
            authState = .unauthenticated
            isAuthenticated = false
        }
        
        Logger.debug("📱 AuthStateManager: Updated to unauthenticated state")
    }
    
    private func updateErrorState(_ error: Error) async {
        await MainActor.run {
            authState = .error(error.localizedDescription)
            isAuthenticated = false
        }
        Logger.error("❌ AuthStateManager: Updated to error state: \(error.localizedDescription)")
    }
    
    /// Helper method to determine if an error is authorization-related
    private func isAuthorizationError(_ error: Error) -> Bool {
        // Add logic to check if error is authorization-related
        let errorMessage = error.localizedDescription.lowercased()
        return errorMessage.contains("unauthorized") ||
        errorMessage.contains("401") ||
        errorMessage.contains("invalid token") ||
        errorMessage.contains("expired")
    }
    
    deinit {
        credentialCheckTimer?.invalidate()
        credentialCheckTimer = nil
    }
}

// MARK: - Auth Error Types
enum AuthError: Error, LocalizedError {
    case noUserIdFound
    case invalidToken
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .noUserIdFound:
            return "No user ID found in stored authentication data"
        case .invalidToken:
            return "Authentication token is invalid"
        case .networkError:
            return "Network error occurred during authentication"
        case .unknown:
            return "An unknown authentication error occurred"
        }
    }
}

// MARK: - Debug Support
#if DEBUG
extension AuthStateManager {
    func debugCurrentState() {
        Task {
            let token = await tokenManager.getToken()
            let userId = await tokenManager.getCurrentUserId()
            
            await MainActor.run {
                print("🔍 [AuthStateManager Debug]")
                print("  - AuthState: \(authState)")
                print("  - IsAuthenticated: \(isAuthenticated)")
                print("  - CurrentUser: \(currentUser?.displayName ?? "nil")")
                print("  - Token: \(token != nil ? "Present" : "nil")")
                print("  - UserId: \(userId?.description ?? "nil")")
            }
        }
    }
    
    /// Método de debug para forzar logout (útil para testing)
    func debugForceLogout() async {
        Logger.debug("🔧 Debug: Force logout triggered")
        await logout()
    }
}
#endif
