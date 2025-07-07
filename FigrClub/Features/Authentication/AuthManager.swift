//
//  AuthManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation
import Combine

@MainActor
final class AuthStateManager: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private let authRepository: AuthRepositoryProtocol
    private let tokenManager: TokenManager
    private var cancellables = Set<AnyCancellable>()
    
    nonisolated init(authRepository: AuthRepositoryProtocol, tokenManager: TokenManager) {
        self.authRepository = authRepository
        self.tokenManager = tokenManager
        
        Task { @MainActor in
            self.setupSubscriptions()
            await self.checkInitialAuthState()
        }
    }
    
    // MARK: - Public Methods
    
    func login(email: String, password: String) async -> Result<User, Error> {
        authState = .loading
        
        do {
            let user = try await authRepository.login(email: email, password: password)
            await updateAuthenticatedState(with: user)
            Logger.info("Login successful for user: \(user.username)")
            return .success(user)
        } catch {
            await updateErrorState(error)
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
            await updateAuthenticatedState(with: user)
            Logger.info("Registration successful for user: \(user.username)")
            return .success(user)
        } catch {
            await updateErrorState(error)
            Logger.error("Registration failed: \(error)")
            return .failure(error)
        }
    }
    
    func logout() async {
        authState = .loading
        
        do {
            try await authRepository.logout()
            await updateUnauthenticatedState()
            Logger.info("Logout successful")
        } catch {
            Logger.error("Logout failed: \(error)")
            // Even if logout fails on server, clear local state
            await updateUnauthenticatedState()
        }
    }
    
    func refreshToken() async -> Bool {
        do {
            let user = try await authRepository.refreshToken()
            await updateAuthenticatedState(with: user)
            Logger.info("Token refresh successful")
            return true
        } catch {
            await updateUnauthenticatedState()
            Logger.error("Token refresh failed: \(error)")
            return false
        }
    }
    
    func checkInitialAuthState() async {
        Logger.info("Checking initial authentication state")
        
        // Check if we have a token
        guard await tokenManager.getToken() != nil else {
            await updateUnauthenticatedState()
            Logger.info("No token found, user is unauthenticated")
            return
        }
        
        // Try to get current user
        do {
            let user = try await authRepository.getCurrentUser()
            await updateAuthenticatedState(with: user)
            Logger.info("Authentication check successful for user: \(user.username)")
        } catch {
            // Token might be invalid, try to refresh
            Logger.warning("Failed to get current user, attempting token refresh")
            let refreshSuccess = await refreshToken()
            if !refreshSuccess {
                await updateUnauthenticatedState()
            }
        }
    }
    
    func updateUser(_ user: User) async {
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
                    Task { @MainActor in
                        await self?.updateUnauthenticatedState()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateAuthenticatedState(with user: User) async {
        currentUser = user
        authState = .authenticated(user)
        isAuthenticated = true
    }
    
    private func updateUnauthenticatedState() async {
        currentUser = nil
        authState = .unauthenticated
        isAuthenticated = false
    }
    
    private func updateErrorState(_ error: Error) async {
        authState = .error(error.localizedDescription)
        isAuthenticated = false
    }
}

// MARK: - Debug Support
#if DEBUG
extension AuthStateManager {
    func debugCurrentState() {
        print("🔍 [AuthStateManager Debug]")
        print("  - AuthState: \(authState)")
        print("  - IsAuthenticated: \(isAuthenticated)")
        print("  - CurrentUser: \(currentUser?.username ?? "nil")")
    }
}
#endif
