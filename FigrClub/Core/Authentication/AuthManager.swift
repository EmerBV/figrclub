//
//  AuthManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Combine

// MARK: - Authentication State
enum AuthState {
    case unauthenticated
    case authenticated(User)
    case loading
    case error(APIError)
}

// MARK: - Auth Manager Protocol
protocol AuthManagerProtocol: ObservableObject {
    var authState: AuthState { get }
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    var isLoading: Bool { get }
    
    func login(email: String, password: String) async -> Result<User, APIError>
    func register(_ request: RegisterRequest) async -> Result<User, APIError>
    func logout()
    func refreshTokenIfNeeded() async -> Bool
    func getCurrentUser() async -> Result<User, APIError>
    
    func loginWithValidation(email: String, password: String) async -> Result<User, AuthValidationError>
}

// MARK: - Auth Manager Implementation
@MainActor
final class AuthManager: AuthManagerProtocol {
    
    // MARK: - Published Properties
    @Published private(set) var authState: AuthState = .unauthenticated
    @Published private(set) var currentUser: User?
    
    // MARK: - Computed Properties
    var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }
    
    var isLoading: Bool {
        if case .loading = authState {
            return true
        }
        return false
    }
    
    // MARK: - Private Properties
    private let apiService: APIServiceProtocol
    private let tokenManager: TokenManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(apiService: APIServiceProtocol = APIService.shared,
         tokenManager: TokenManager = TokenManager.shared) {
        self.apiService = apiService
        self.tokenManager = tokenManager
        
        setupObservers()
        checkInitialAuthState()
    }
    
    // MARK: - Public Methods
    
    func login(email: String, password: String) async -> Result<User, APIError> {
        await setLoadingState()
        
        do {
            let loginRequest = LoginRequest(email: email, password: password)
            let authResponse: AuthResponse = try await apiService
                .request(endpoint: .login, body: loginRequest)
                .async()
            
            // Save tokens
            tokenManager.saveTokens(
                accessToken: authResponse.authToken.token,
                userId: authResponse.userId
            )
            
            // Get user details
            return await getCurrentUser()
            
        } catch {
            let apiError = error as? APIError ?? APIError(
                message: "Login failed",
                code: "LOGIN_FAILED",
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
            
            await setErrorState(apiError)
            return .failure(apiError)
        }
    }
    
    func register(_ request: RegisterRequest) async -> Result<User, APIError> {
        await setLoadingState()
        
        do {
            let response: RegisterResponse = try await apiService
                .request(endpoint: .register, body: request)
                .async()
            
            // For registration, user might need email verification
            // So we don't automatically log them in
            await setUnauthenticatedState()
            
            // Return user data even if not authenticated yet
            let user = User(
                id: response.userId,
                firstName: request.firstName,
                lastName: request.lastName,
                email: response.email,
                username: request.username,
                userType: request.userType,
                subscriptionType: .free,
                isVerified: response.emailVerified,
                profileImageUrl: nil,
                bio: nil,
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
            
            return .success(user)
            
        } catch {
            let apiError = error as? APIError ?? APIError(
                message: "Registration failed",
                code: "REGISTRATION_FAILED",
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
            
            await setErrorState(apiError)
            return .failure(apiError)
        }
    }
    
    func logout() {
        tokenManager.clearTokens()
        currentUser = nil
        authState = .unauthenticated
        
        // Clear any cached data
        clearUserData()
        
        #if DEBUG
        print("✅ User logged out successfully")
        #endif
    }
    
    func refreshTokenIfNeeded() async -> Bool {
        guard tokenManager.shouldRefreshToken() else {
            return true // Token is still valid
        }
        
        let result = await tokenManager.refreshAccessToken()
        
        switch result {
        case .success:
            return true
        case .failure:
            // If refresh fails, logout user
            logout()
            return false
        }
    }
    
    func getCurrentUser() async -> Result<User, APIError> {
        guard let userId = tokenManager.getUserId() else {
            let error = APIError(
                message: "No user ID found",
                code: "NO_USER_ID",
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
            await setErrorState(error)
            return .failure(error)
        }
        
        do {
            let user: User = try await apiService
                .request(endpoint: .getUserById(userId), body: nil)
                .async()
            
            await setAuthenticatedState(user)
            return .success(user)
            
        } catch {
            let apiError = error as? APIError ?? APIError(
                message: "Failed to get user data",
                code: "GET_USER_FAILED",
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
            
            await setErrorState(apiError)
            return .failure(apiError)
        }
    }
    
    func updateCurrentUser(_ updatedUser: User) {
        currentUser = updatedUser
        authState = .authenticated(updatedUser)
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe token manager authentication changes
        tokenManager.$isAuthenticated
            .removeDuplicates()
            .sink { [weak self] isAuthenticated in
                Task { @MainActor in
                    if isAuthenticated && self?.currentUser == nil {
                        // Token exists but no user data, fetch user
                        _ = await self?.getCurrentUser()
                    } else if !isAuthenticated {
                        // Token removed, logout
                        self?.logout()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkInitialAuthState() {
        Task {
            if tokenManager.isAuthenticated {
                // Check if token is still valid by getting user data
                _ = await getCurrentUser()
            } else {
                await setUnauthenticatedState()
            }
        }
    }
    
    private func clearUserData() {
        // Clear any cached user data, CoreData, UserDefaults, etc.
        // This can be expanded based on your app's needs
        
        // Example: Clear CoreData
        // CoreDataManager.shared.clearAllData()
        
        // Example: Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "user_preferences")
        UserDefaults.standard.removeObject(forKey: "cached_user_data")
    }
    
    // MARK: - State Management
    
    private func setLoadingState() async {
        authState = .loading
    }
    
    private func setAuthenticatedState(_ user: User) async {
        currentUser = user
        authState = .authenticated(user)
    }
    
    private func setUnauthenticatedState() async {
        currentUser = nil
        authState = .unauthenticated
    }
    
    private func setErrorState(_ error: APIError) async {
        authState = .error(error)
    }
    
}

// MARK: - Convenience Methods
extension AuthManager {
    
    func loginWithValidation(email: String, password: String) async -> Result<User, AuthValidationError> {
        // Validate input
        if let validationError = validateLoginInput(email: email, password: password) {
            return .failure(validationError)
        }
        
        let result = await login(email: email, password: password)
        
        switch result {
        case .success(let user):
            return .success(user)
        case .failure(let apiError):
            let validationError = AuthValidationError.serverError(apiError.message)
            return .failure(validationError)
        }
    }
    
    
    func registerWithValidation(_ request: RegisterRequest) async -> Result<User, AuthValidationError> {
        // Validate input
        if let validationError = validateRegistrationInput(request) {
            return .failure(validationError)
        }
        
        let result = await register(request)
        
        switch result {
        case .success(let user):
            return .success(user)
        case .failure(let apiError):
            let validationError = AuthValidationError.serverError(apiError.message)
            return .failure(validationError)
        }
    }
    
    private func validateLoginInput(email: String, password: String) -> AuthValidationError? {
        if email.isEmpty {
            return .emptyEmail
        }
        
        if !email.isValidEmail {
            return .invalidEmail
        }
        
        if password.isEmpty {
            return .emptyPassword
        }
        
        if password.count < 6 {
            return .weakPassword
        }
        
        return nil
    }
    
    private func validateRegistrationInput(_ request: RegisterRequest) -> AuthValidationError? {
        if request.firstName.isEmpty {
            return .emptyFirstName
        }
        
        if request.lastName.isEmpty {
            return .emptyLastName
        }
        
        if request.email.isEmpty {
            return .emptyEmail
        }
        
        if !request.email.isValidEmail {
            return .invalidEmail
        }
        
        if request.password.isEmpty {
            return .emptyPassword
        }
        
        if request.password.count < 8 {
            return .weakPassword
        }
        
        if request.username.isEmpty {
            return .emptyUsername
        }
        
        if request.username.count < 3 {
            return .shortUsername
        }
        
        return nil
    }
}

// MARK: - Supporting Models
struct RegisterResponse: Codable {
    let userId: Int
    let email: String
    let fullName: String
    let emailVerified: Bool
    let emailSent: Bool
}

// MARK: - Validation Errors
enum AuthValidationError: LocalizedError {
    case emptyEmail
    case invalidEmail
    case emptyPassword
    case weakPassword
    case emptyFirstName
    case emptyLastName
    case emptyUsername
    case shortUsername
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyEmail:
            return "El email es requerido"
        case .invalidEmail:
            return "El formato del email no es válido"
        case .emptyPassword:
            return "La contraseña es requerida"
        case .weakPassword:
            return "La contraseña debe tener al menos 8 caracteres"
        case .emptyFirstName:
            return "El nombre es requerido"
        case .emptyLastName:
            return "El apellido es requerido"
        case .emptyUsername:
            return "El nombre de usuario es requerido"
        case .shortUsername:
            return "El nombre de usuario debe tener al menos 3 caracteres"
        case .serverError(let message):
            return message
        }
    }
}

// MARK: - String Extensions
extension String {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
}
