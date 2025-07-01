//
//  AuthManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Combine
import UserNotifications

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
    
    var authStatePublisher: AnyPublisher<AuthState, Never> {
        $authState.eraseToAnyPublisher()
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
            
            // Primero hacemos login
            let authResponse: AuthResponse = try await apiService
                .request(endpoint: .login, body: loginRequest)
                .async()
            
            Logger.shared.info("Login successful for user: \(authResponse.userId)", category: "auth")
            
            // Guardamos los tokens
            tokenManager.saveTokens(
                accessToken: authResponse.authToken.token,
                userId: authResponse.userId
            )
            
            // Luego obtenemos los datos del usuario
            let userResult = await getCurrentUser()
            
            switch userResult {
            case .success(let user):
                await setAuthenticatedState(user)
                Analytics.shared.logLogin(method: "email")
                return .success(user)
            case .failure(let error):
                // Si falla obtener el usuario, creamos uno temporal con los datos que tenemos
                Logger.shared.warning("Failed to get user details after login, creating temporary user", category: "auth")
                
                let temporaryUser = User(
                    id: authResponse.userId,
                    firstName: "Usuario", // Placeholder
                    lastName: "", // Placeholder
                    email: authResponse.email,
                    username: authResponse.email.components(separatedBy: "@").first ?? "user",
                    userType: .regular,
                    subscriptionType: .free,
                    isVerified: false,
                    profileImageUrl: nil,
                    bio: nil,
                    createdAt: ISO8601DateFormatter().string(from: Date())
                )
                
                await setAuthenticatedState(temporaryUser)
                
                // Intentamos obtener los datos reales del usuario en background
                Task {
                    _ = await getCurrentUser()
                }
                
                return .success(temporaryUser)
            }
            
        } catch {
            let apiError = error as? APIError ?? APIError(
                message: "Login failed: \(error.localizedDescription)",
                code: "LOGIN_FAILED",
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
            
            Logger.shared.error("Login failed", error: apiError, category: "auth")
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
            
            // Para el registro, el usuario podría necesitar verificación de email
            await setUnauthenticatedState()
            
            // Retornamos datos del usuario aunque no esté autenticado aún
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
            
            Analytics.shared.logSignup(method: "email")
            return .success(user)
            
        } catch {
            let apiError = error as? APIError ?? APIError(
                message: "Registration failed: \(error.localizedDescription)",
                code: "REGISTRATION_FAILED",
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
            
            Logger.shared.error("Registration failed", error: apiError, category: "auth")
            await setErrorState(apiError)
            return .failure(apiError)
        }
    }
    
    func logout() {
        tokenManager.clearTokens()
        currentUser = nil
        authState = .unauthenticated
        
        // Limpiar datos en caché
        clearUserData()
        
        Analytics.shared.logLogout()
        Logger.shared.info("User logged out successfully", category: "auth")
    }
    
    func refreshTokenIfNeeded() async -> Bool {
        guard tokenManager.shouldRefreshToken() else {
            return true // Token sigue siendo válido
        }
        
        let result = await tokenManager.refreshAccessToken()
        
        switch result {
        case .success:
            return true
        case .failure(let error):
            Logger.shared.error("Failed to refresh token", error: error, category: "auth")
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
            Logger.shared.info("Fetching user data for userId: \(userId)", category: "auth")
            
            let user: User = try await apiService
                .request(endpoint: .getUserById(userId), body: nil)
                .async()
            
            Logger.shared.info("Successfully fetched user data: \(user.email)", category: "auth")
            await setAuthenticatedState(user)
            return .success(user)
            
        } catch {
            let apiError = error as? APIError ?? APIError(
                message: "Failed to get user data: \(error.localizedDescription)",
                code: "GET_USER_FAILED",
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
            
            Logger.shared.error("Failed to get user data", error: apiError, category: "auth")
            
            // No establecemos error state aquí si ya estamos autenticados
            if case .authenticated = authState {
                Logger.shared.info("Keeping current auth state despite user fetch failure", category: "auth")
            } else {
                await setErrorState(apiError)
            }
            
            return .failure(apiError)
        }
    }
    
    func updateCurrentUser(_ updatedUser: User) {
        currentUser = updatedUser
        authState = .authenticated(updatedUser)
        Logger.shared.info("User data updated", category: "auth")
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observar cambios en la autenticación del token manager
        tokenManager.$isAuthenticated
            .removeDuplicates()
            .sink { [weak self] isAuthenticated in
                Task { @MainActor in
                    if !isAuthenticated {
                        // Token fue removido, hacer logout
                        self?.logout()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkInitialAuthState() {
        Task {
            if tokenManager.isAuthenticated {
                Logger.shared.info("Found existing token, attempting to get user data", category: "auth")
                let result = await getCurrentUser()
                
                switch result {
                case .success:
                    Logger.shared.info("Successfully restored user session", category: "auth")
                case .failure:
                    Logger.shared.warning("Failed to restore user session, clearing tokens", category: "auth")
                    logout()
                }
            } else {
                Logger.shared.info("No existing token found", category: "auth")
                await setUnauthenticatedState()
            }
        }
    }
    
    private func clearUserData() {
        // Limpiar datos en caché, CoreData, UserDefaults, etc.
        UserDefaults.standard.removeObject(forKey: "user_preferences")
        UserDefaults.standard.removeObject(forKey: "cached_user_data")
        
        // Limpiar notificaciones locales
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    // MARK: - State Management
    
    private func setLoadingState() async {
        authState = .loading
        Logger.shared.debug("Auth state: loading", category: "auth")
    }
    
    private func setAuthenticatedState(_ user: User) async {
        currentUser = user
        authState = .authenticated(user)
        Logger.shared.info("Auth state: authenticated (\(user.email))", category: "auth")
        
        // Configurar analytics y crash reporting
        Analytics.shared.setUserId(String(user.id))
        Analytics.shared.setUserType(user.userType.rawValue)
        CrashReporter.shared.setUserId(String(user.id))
        CrashReporter.shared.setUserEmail(user.email)
    }
    
    private func setUnauthenticatedState() async {
        currentUser = nil
        authState = .unauthenticated
        Logger.shared.debug("Auth state: unauthenticated", category: "auth")
        
        // Limpiar analytics
        Analytics.shared.setUserId(nil)
    }
    
    private func setErrorState(_ error: APIError) async {
        authState = .error(error)
        Logger.shared.debug("Auth state: error (\(error.message))", category: "auth")
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
}
