//
//  AuthManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation
import Combine

@MainActor
final class AuthManager: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private let authRepository: AuthRepositoryProtocol
    private let tokenManager: TokenManager
    private var cancellables = Set<AnyCancellable>()
    
    // FIXED: Removemos @MainActor del init para que funcione con Swinject
    nonisolated init(authRepository: AuthRepositoryProtocol, tokenManager: TokenManager) {
        self.authRepository = authRepository
        self.tokenManager = tokenManager
        
        // Movemos la configuración async a un método separado
        Task { @MainActor in
            await self.setupAfterInit()
        }
    }
    
    // Método para configuración post-inicialización
    private func setupAfterInit() async {
        setupSubscriptions()
        await checkAuthenticationStatus()
    }
    
    // MARK: - Public Methods
    
    func login(email: String, password: String) async -> Result<User, Error> {
        authState = .loading
        
        do {
            let user = try await authRepository.login(email: email, password: password)
            currentUser = user
            authState = .authenticated(user)
            isAuthenticated = true
            Logger.info("Login successful for user: \(user.username)")
            return .success(user)
        } catch {
            authState = .error(error)
            isAuthenticated = false
            Logger.error("Login failed: \(error)")
            return .failure(error)
        }
    }
    
    func register(email: String, password: String, username: String, fullName: String?) async -> Result<User, Error> {
        authState = .loading
        
        do {
            let user = try await authRepository.register(
                email: email,
                password: password,
                username: username,
                fullName: fullName
            )
            currentUser = user
            authState = .authenticated(user)
            isAuthenticated = true
            Logger.info("Registration successful for user: \(user.username)")
            return .success(user)
        } catch {
            authState = .error(error)
            isAuthenticated = false
            Logger.error("Registration failed: \(error)")
            return .failure(error)
        }
    }
    
    func logout() async {
        authState = .loading
        
        do {
            try await authRepository.logout()
            currentUser = nil
            authState = .unauthenticated
            isAuthenticated = false
            Logger.info("Logout successful")
        } catch {
            Logger.error("Logout failed: \(error)")
            // Even if logout fails on server, clear local state
            currentUser = nil
            authState = .unauthenticated
            isAuthenticated = false
        }
    }
    
    func refreshToken() async -> Result<User, Error> {
        do {
            let user = try await authRepository.refreshToken()
            currentUser = user
            authState = .authenticated(user)
            isAuthenticated = true
            Logger.info("Token refresh successful")
            return .success(user)
        } catch {
            // Token refresh failed, user needs to login again
            currentUser = nil
            authState = .unauthenticated
            isAuthenticated = false
            Logger.error("Token refresh failed: \(error)")
            return .failure(error)
        }
    }
    
    func checkAuthenticationStatus() async {
        Logger.info("Checking authentication status")
        
        // Check if we have a token
        guard await tokenManager.getToken() != nil else {
            authState = .unauthenticated
            isAuthenticated = false
            Logger.info("No token found, user is unauthenticated")
            return
        }
        
        // Try to get current user
        do {
            let user = try await authRepository.getCurrentUser()
            currentUser = user
            authState = .authenticated(user)
            isAuthenticated = true
            Logger.info("Authentication check successful for user: \(user.username)")
        } catch {
            // Token might be invalid, try to refresh
            Logger.warning("Failed to get current user, attempting token refresh")
            let refreshResult = await refreshToken()
            
            if case .failure = refreshResult {
                currentUser = nil
                authState = .unauthenticated
                isAuthenticated = false
                Logger.info("Token refresh failed, user needs to login again")
            }
        }
    }
    
    func updateUser(_ user: User) {
        currentUser = user
        authState = .authenticated(user)
        Logger.info("User updated: \(user.username)")
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Listen to token manager authentication changes
        tokenManager.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                if !isAuthenticated && self?.isAuthenticated == true {
                    // Token was cleared, update auth state
                    self?.currentUser = nil
                    self?.authState = .unauthenticated
                    self?.isAuthenticated = false
                }
            }
            .store(in: &cancellables)
    }
}
