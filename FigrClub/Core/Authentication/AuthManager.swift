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

// MARK: - Auth Validation Error
enum AuthValidationError: LocalizedError {
    case emptyEmail
    case invalidEmailFormat
    case emptyPassword
    case passwordTooShort
    case emptyFirstName
    case emptyLastName
    case emptyUsername
    case usernameInvalid
    case passwordMismatch
    case termsNotAccepted
    case privacyNotAccepted
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyEmail:
            return "El email es requerido"
        case .invalidEmailFormat:
            return "Formato de email inválido"
        case .emptyPassword:
            return "La contraseña es requerida"
        case .passwordTooShort:
            return "La contraseña debe tener al menos 6 caracteres"
        case .emptyFirstName:
            return "El nombre es requerido"
        case .emptyLastName:
            return "El apellido es requerido"
        case .emptyUsername:
            return "El nombre de usuario es requerido"
        case .usernameInvalid:
            return "El nombre de usuario debe tener al menos 3 caracteres y solo contener letras, números y guiones bajos"
        case .passwordMismatch:
            return "Las contraseñas no coinciden"
        case .termsNotAccepted:
            return "Debes aceptar los términos y condiciones"
        case .privacyNotAccepted:
            return "Debes aceptar la política de privacidad"
        case .serverError(let message):
            return message
        }
    }
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
    private var retryCount = 0
    private let maxRetries = 3
    
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
            
            // Crear usuario temporal con datos del login
            let fallbackUser = createFallbackUser(from: authResponse)
            
            // Intentamos obtener los datos reales del usuario
            let userResult = await getCurrentUser()
            
            switch userResult {
            case .success(let user):
                // Si obtenemos los datos reales, los usamos
                await setAuthenticatedState(user)
                Analytics.shared.logLogin(method: "email")
                resetRetryCount()
                return .success(user)
                
            case .failure(let error):
                Logger.shared.warning("Failed to get user details after login: \(error.message)", category: "auth")
                
                // Manejar diferentes tipos de errores
                return await handleUserDataError(error: error, fallbackUser: fallbackUser)
            }
            
        } catch {
            let apiError = error as? APIError ?? APIError(
                message: "Login failed: \(error.localizedDescription)",
                code: "LOGIN_FAILED"
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
                isPrivate: false,
                profileImageUrl: nil,
                bio: nil,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            Analytics.shared.logSignup(method: "email")
            return .success(user)
            
        } catch {
            let apiError = error as? APIError ?? APIError(
                message: "Registration failed: \(error.localizedDescription)",
                code: "REGISTRATION_FAILED",
                statusCode: error.localizedDescription.contains("400") ? 400 : 500,
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
        resetRetryCount()
        
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
                code: "NO_USER_ID"
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
            resetRetryCount()
            return .success(user)
            
        } catch {
            let apiError = error as? APIError ?? APIError(
                message: "Failed to get user data: \(error.localizedDescription)",
                code: "GET_USER_FAILED"
            )
            
            Logger.shared.error("Failed to get user data", error: apiError, category: "auth")
            
            // Manejar diferentes tipos de errores
            switch apiError.code {
            case "EMPTY_USER_DATA", "MALFORMED_SUCCESS_RESPONSE":
                Logger.shared.warning("Backend returned empty user data", category: "auth")
                
                // No cambiar el estado si ya estamos autenticados
                if case .authenticated = authState {
                    Logger.shared.info("Keeping current auth state despite empty data error", category: "auth")
                } else {
                    await setErrorState(apiError)
                }
                
            default:
                // Para otros errores, mantener estado si ya estamos autenticados
                if case .authenticated = authState {
                    Logger.shared.info("Keeping current auth state despite user fetch failure", category: "auth")
                } else {
                    await setErrorState(apiError)
                }
            }
            
            return .failure(apiError)
        }
    }
    
    func updateCurrentUser(_ updatedUser: User) {
        currentUser = updatedUser
        authState = .authenticated(updatedUser)
        Logger.shared.info("User data updated", category: "auth")
    }
    
    // MARK: - Validation Methods
    
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
    
    private func createFallbackUser(from authResponse: AuthResponse) -> User {
        return User(
            id: authResponse.userId,
            firstName: extractFirstName(from: authResponse.email),
            lastName: "",
            email: authResponse.email,
            username: extractUsername(from: authResponse.email),
            userType: .regular,
            subscriptionType: .free,
            isVerified: false,
            profileImageUrl: nil,
            bio: nil,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    private func handleUserDataError(error: APIError, fallbackUser: User) async -> Result<User, APIError> {
        switch error.code {
        case "EMPTY_USER_DATA", "MALFORMED_SUCCESS_RESPONSE":
            // Error del backend - datos vacíos
            await setAuthenticatedState(fallbackUser)
            Analytics.shared.logLogin(method: "email")
            
            // Mostrar alerta al usuario
            postUserAlert(
                title: "Aviso",
                message: "Login exitoso, pero algunos datos de perfil no están disponibles temporalmente. Puedes completarlos en tu perfil.",
                type: .warning
            )
            
            // Reintentar en background
            scheduleUserDataRetry()
            
            return .success(fallbackUser)
            
        case "DECODING_ERROR":
            // Error de decodificación - problema de formato
            await setAuthenticatedState(fallbackUser)
            Analytics.shared.logLogin(method: "email")
            
            Logger.shared.error("User data format error - using fallback", error: error, category: "auth")
            
            // Reintentar en background
            scheduleUserDataRetry()
            
            return .success(fallbackUser)
            
        default:
            // Otros errores (network, etc)
            await setAuthenticatedState(fallbackUser)
            Analytics.shared.logLogin(method: "email")
            
            // Reintentar en background para cualquier otro error
            scheduleUserDataRetry()
            
            return .success(fallbackUser)
        }
    }
    
    private func scheduleUserDataRetry() {
        guard retryCount < maxRetries else {
            Logger.shared.warning("Max retries reached for getUserData", category: "auth")
            return
        }
        
        Task {
            await retryGetUserDataWithBackoff()
        }
    }
    
    private func retryGetUserDataWithBackoff() async {
        guard retryCount < maxRetries else {
            Logger.shared.warning("Max retries reached for getUserData", category: "auth")
            return
        }
        
        retryCount += 1
        
        // Esperar con backoff exponencial: 5s, 15s, 45s
        let delay = pow(3.0, Double(retryCount)) * 5.0
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        Logger.shared.info("Retrying getUserData attempt \(retryCount)/\(maxRetries)", category: "auth")
        
        let result = await getCurrentUser()
        
        switch result {
        case .success(let user):
            Logger.shared.info("Successfully retrieved user data on retry \(retryCount)", category: "auth")
            await setAuthenticatedState(user)
            resetRetryCount()
            
            // Notificar que los datos fueron actualizados
            postUserAlert(
                title: "Datos actualizados",
                message: "Tus datos de perfil han sido sincronizados correctamente.",
                type: .success
            )
            
            NotificationCenter.default.post(
                name: .userDataUpdated,
                object: user
            )
            
        case .failure(let error):
            if error.code == "EMPTY_USER_DATA" || error.code == "MALFORMED_SUCCESS_RESPONSE" {
                // Continuar reintentando para errores de backend
                await retryGetUserDataWithBackoff()
            } else {
                Logger.shared.warning("Stopping retries due to non-backend error: \(error.code)", category: "auth")
                resetRetryCount()
            }
        }
    }
    
    private func resetRetryCount() {
        retryCount = 0
    }
    
    private func postUserAlert(title: String, message: String, type: UserAlert.AlertType) {
        NotificationCenter.default.post(
            name: .showUserAlert,
            object: UserAlert(
                title: title,
                message: message,
                type: type
            )
        )
    }
    
    private func clearUserData() {
        // Limpiar datos en caché, CoreData, UserDefaults, etc.
        UserDefaults.standard.removeObject(forKey: "user_preferences")
        UserDefaults.standard.removeObject(forKey: "cached_user_data")
        
        // Limpiar notificaciones locales
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    private func extractFirstName(from email: String) -> String {
        let username = email.components(separatedBy: "@").first ?? "Usuario"
        return username.components(separatedBy: ".").first?.capitalized ?? username.capitalized
    }
    
    private func extractUsername(from email: String) -> String {
        return email.components(separatedBy: "@").first ?? "user"
    }
    
    // MARK: - Validation Helpers
    
    private func validateLoginInput(email: String, password: String) -> AuthValidationError? {
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .emptyEmail
        }
        
        if !isValidEmail(email) {
            return .invalidEmailFormat
        }
        
        if password.isEmpty {
            return .emptyPassword
        }
        
        if password.count < 6 {
            return .passwordTooShort
        }
        
        return nil
    }
    
    private func validateRegistrationInput(_ request: RegisterRequest) -> AuthValidationError? {
        if request.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .emptyFirstName
        }
        
        if request.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .emptyLastName
        }
        
        if request.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .emptyEmail
        }
        
        if !isValidEmail(request.email) {
            return .invalidEmailFormat
        }
        
        if request.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .emptyUsername
        }
        
        if !isValidUsername(request.username) {
            return .usernameInvalid
        }
        
        if request.password.isEmpty {
            return .emptyPassword
        }
        
        if request.password.count < 6 {
            return .passwordTooShort
        }
        
        // Verificar aceptación de términos legales
        let hasTermsAcceptance = request.legalAcceptances.contains { acceptance in
            acceptance.documentType == "TERMS_OF_SERVICE"
        }
        
        if !hasTermsAcceptance {
            return .termsNotAccepted
        }
        
        return nil
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidUsername(_ username: String) -> Bool {
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
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
