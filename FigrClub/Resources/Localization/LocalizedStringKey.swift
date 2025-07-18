//
//  LocalizedStringKey.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 16/7/25.
//

import Foundation

// MARK: - Localized String Key
enum LocalizedStringKey: String, CaseIterable {
    
    // MARK: - General
    case appName = "app_name"
    case cancel = "cancel"
    case confirm = "confirm"
    case ok = "ok"
    case error = "error"
    case loading = "loading"
    case retry = "retry"
    case close = "close"
    case save = "save"
    case edit = "edit"
    case delete = "delete"
    case done = "done"
    case next = "next"
    case previous = "previous"
    case continueButton = "continue"
    case skip = "skip"
    
    // MARK: - Authentication
    case login = "login"
    case register = "register"
    case logout = "logout"
    case loginTitle = "login_title"
    case registerTitle = "register_title"
    case createAccount = "create_account"
    case welcomeBack = "welcome_back"
    case welcomeBackSubtitle = "welcome_back_subtitle"
    case joinCommunity = "join_community"
    case createAccountSubtitle = "create_account_subtitle"
    case alreadyHaveAccount = "already_have_account"
    case dontHaveAccount = "dont_have_account"
    case forgotPassword = "forgot_password"
    
    // MARK: - Form Fields
    case email = "email"
    case password = "password"
    case confirmPassword = "confirm_password"
    case username = "username"
    case fullName = "full_name"
    case firstName = "first_name"
    case lastName = "last_name"
    case emailPlaceholder = "email_placeholder"
    case passwordPlaceholder = "password_placeholder"
    case confirmPasswordPlaceholder = "confirm_password_placeholder"
    case usernamePlaceholder = "username_placeholder"
    case fullNamePlaceholder = "full_name_placeholder"
    
    // MARK: - Validation Messages
    case emailRequired = "email_required"
    case emailInvalid = "email_invalid"
    case passwordRequired = "password_required"
    case passwordTooShort = "password_too_short"
    case passwordTooLong = "password_too_long"
    case passwordMustContainLetter = "password_must_contain_letter"
    case passwordMustContainNumber = "password_must_contain_number"
    case passwordMustContainSpecialChar = "password_must_contain_special_char"
    case passwordNoSpaces = "password_no_spaces"
    case passwordsDontMatch = "passwords_dont_match"
    case usernameRequired = "username_required"
    case usernameTooShort = "username_too_short"
    case usernameTooLong = "username_too_long"
    case usernameInvalidChars = "username_invalid_chars"
    case fullNameRequired = "full_name_required"
    case fullNameTooShort = "full_name_too_short"
    case fullNameTooLong = "full_name_too_long"
    case fullNameInvalidChars = "full_name_invalid_chars"
    
    // MARK: - Password Requirements
    case passwordRequirements = "password_requirements"
    case passwordMinLength = "password_min_length"
    case passwordMustHaveLetter = "password_must_have_letter"
    case passwordMustHaveNumber = "password_must_have_number"
    case passwordMustHaveSpecial = "password_must_have_special"
    
    // MARK: - Terms and Conditions
    case acceptTerms = "accept_terms"
    case termsAndConditions = "terms_and_conditions"
    case privacyPolicy = "privacy_policy"
    case acceptedAt = "accepted_at"
    
    // MARK: - Consents
    case consents = "consents"
    case dataProcessing = "data_processing"
    case dataProcessingDescription = "data_processing_description"
    case functionalCookies = "functional_cookies"
    case functionalCookiesDescription = "functional_cookies_description"
    
    // MARK: - Email Verification
    case emailVerification = "email_verification"
    case verifyEmail = "verify_email"
    case emailSent = "email_sent"
    case emailSentMessage = "email_sent_message"
    case emailSentInstructions = "email_sent_instructions"
    case didntReceiveEmail = "didnt_receive_email"
    case resendEmail = "resend_email"
    
    // MARK: - Loading States
    case loggingIn = "logging_in"
    case creatingAccount = "creating_account"
    case signingOut = "signing_out"
    case verifying = "verifying"
    case processing = "processing"
    
    // MARK: - Error Messages
    case networkError = "network_error"
    case authError = "auth_error"
    case validationError = "validation_error"
    case unknownError = "unknown_error"
    case serverError = "server_error"
    case connectionError = "connection_error"
    case timeoutError = "timeout_error"
    case invalidCredentials = "invalid_credentials"
    case userAlreadyExists = "user_already_exists"
    case weakPassword = "weak_password"
    case emailAlreadyInUse = "email_already_in_use"
    case userNotFound = "user_not_found"
    case tooManyRequests = "too_many_requests"
    
    // MARK: - Success Messages
    case loginSuccessful = "login_successful"
    case registrationSuccessful = "registration_successful"
    case emailVerified = "email_verified"
    case passwordChanged = "password_changed"
    case profileUpdated = "profile_updated"
    
    // MARK: - Language Settings
    case language = "language"
    case changeLanguage = "change_language"
    case spanish = "spanish"
    case english = "english"
    case systemLanguage = "system_language"
    case languageChanged = "language_changed"
    
    // MARK: - Navigation
    case home = "home"
    case feed = "feed"
    case search = "search"
    case create = "create"
    case marketplace = "marketplace"
    case notifications = "notifications"
    case profile = "profile"
    case settings = "settings"
    
    // MARK: - Legal Documents
    case loadingDocument = "loading_document"
    case noDocumentAvailable = "no_document_available"
    case version = "version"
    
    // MARK: - Computed Properties
    
    var fallbackValue: String {
        switch self {
        // General
        case .appName: return "FigrClub"
        case .cancel: return "Cancelar"
        case .confirm: return "Confirmar"
        case .ok: return "OK"
        case .error: return "Error"
        case .loading: return "Cargando..."
        case .retry: return "Reintentar"
        case .close: return "Cerrar"
        case .save: return "Guardar"
        case .edit: return "Editar"
        case .delete: return "Eliminar"
        case .done: return "Hecho"
        case .next: return "Siguiente"
        case .previous: return "Anterior"
        case .continueButton: return "Continuar"
        case .skip: return "Omitir"
        
        // Authentication
        case .login: return "Iniciar sesión"
        case .register: return "Registrarse"
        case .logout: return "Cerrar sesión"
        case .loginTitle: return "Inicia sesión en FigrClub"
        case .registerTitle: return "Crear cuenta en FigrClub"
        case .createAccount: return "Crear Cuenta"
        case .welcomeBack: return "¡Bienvenido de vuelta!"
        case .welcomeBackSubtitle: return "Inicia sesión para continuar"
        case .joinCommunity: return "Únete a nuestra comunidad"
        case .createAccountSubtitle: return "Crea tu cuenta para empezar"
        case .alreadyHaveAccount: return "¿Ya tienes cuenta? Inicia sesión"
        case .dontHaveAccount: return "¿No tienes cuenta? Regístrate"
        case .forgotPassword: return "¿Olvidaste tu contraseña?"
        
        // Form Fields
        case .email: return "Correo"
        case .password: return "Contraseña"
        case .confirmPassword: return "Confirmar contraseña"
        case .username: return "Nombre de usuario"
        case .fullName: return "Nombre completo"
        case .firstName: return "Nombre"
        case .lastName: return "Apellido"
        case .emailPlaceholder: return "your@email.com"
        case .passwordPlaceholder: return "Crea una contraseña"
        case .confirmPasswordPlaceholder: return "Confirma tu contraseña"
        case .usernamePlaceholder: return "nombreusuario"
        case .fullNamePlaceholder: return "Tu nombre completo"
        
        // Validation Messages
        case .emailRequired: return "El email no puede estar vacío"
        case .emailInvalid: return "Formato de email inválido"
        case .passwordRequired: return "La contraseña no puede estar vacía"
        case .passwordTooShort: return "La contraseña debe tener al menos 8 caracteres"
        case .passwordTooLong: return "La contraseña no puede tener más de 128 caracteres"
        case .passwordMustContainLetter: return "La contraseña debe contener al menos una letra"
        case .passwordMustContainNumber: return "La contraseña debe contener al menos un número"
        case .passwordMustContainSpecialChar: return "La contraseña debe contener al menos un carácter especial (!@#$%^&*)"
        case .passwordNoSpaces: return "La contraseña no puede contener espacios"
        case .passwordsDontMatch: return "Las contraseñas no coinciden"
        case .usernameRequired: return "El nombre de usuario no puede estar vacío"
        case .usernameTooShort: return "El nombre de usuario debe tener al menos 3 caracteres"
        case .usernameTooLong: return "El nombre de usuario no puede tener más de 20 caracteres"
        case .usernameInvalidChars: return "El nombre de usuario solo puede contener letras, números y guiones bajos"
        case .fullNameRequired: return "El nombre completo no puede estar vacío"
        case .fullNameTooShort: return "El nombre completo debe tener al menos 2 caracteres"
        case .fullNameTooLong: return "El nombre completo no puede tener más de 50 caracteres"
        case .fullNameInvalidChars: return "El nombre contiene caracteres no válidos"
        
        // Password Requirements
        case .passwordRequirements: return "Requisitos de contraseña:"
        case .passwordMinLength: return "Al menos 8 caracteres"
        case .passwordMustHaveLetter: return "Al menos una letra"
        case .passwordMustHaveNumber: return "Al menos un número"
        case .passwordMustHaveSpecial: return "Al menos un carácter especial (!@#$%^&*)"
        
        // Terms and Conditions
        case .acceptTerms: return "Acepto los términos y condiciones y la política de privacidad"
        case .termsAndConditions: return "términos y condiciones"
        case .privacyPolicy: return "política de privacidad"
        case .acceptedAt: return "Aceptado el: %@"
        
        // Consents
        case .consents: return "Consentimientos"
        case .dataProcessing: return "Procesamiento de datos"
        case .dataProcessingDescription: return "Acepto el procesamiento de mis datos personales según la política de privacidad."
        case .functionalCookies: return "Cookies funcionales"
        case .functionalCookiesDescription: return "Acepto el uso de cookies funcionales para mejorar la experiencia de usuario."
        
        // Email Verification
        case .emailVerification: return "Verificación de email"
        case .verifyEmail: return "Verifica tu email"
        case .emailSent: return "Email enviado"
        case .emailSentMessage: return "Te hemos enviado un email de verificación a:"
        case .emailSentInstructions: return "Por favor, revisa tu bandeja de entrada y haz clic en el enlace de verificación para completar tu registro."
        case .didntReceiveEmail: return "¿No recibiste el email?"
        case .resendEmail: return "Reenviar"
        
        // Loading States
        case .loggingIn: return "Iniciando sesión..."
        case .creatingAccount: return "Creando cuenta..."
        case .signingOut: return "Cerrando sesión..."
        case .verifying: return "Verificando..."
        case .processing: return "Procesando..."
        
        // Error Messages
        case .networkError: return "Error de conexión. Verifica tu internet."
        case .authError: return "Error de autenticación"
        case .validationError: return "Por favor completa todos los campos correctamente"
        case .unknownError: return "Ha ocurrido un error inesperado"
        case .serverError: return "Error del servidor. Inténtalo más tarde."
        case .connectionError: return "No hay conexión a internet"
        case .timeoutError: return "Tiempo de espera agotado"
        case .invalidCredentials: return "Email o contraseña incorrectos"
        case .userAlreadyExists: return "El usuario ya existe"
        case .weakPassword: return "La contraseña es muy débil"
        case .emailAlreadyInUse: return "Este email ya está en uso"
        case .userNotFound: return "Usuario no encontrado"
        case .tooManyRequests: return "Demasiados intentos. Inténtalo más tarde."
        
        // Success Messages
        case .loginSuccessful: return "¡Sesión iniciada con éxito!"
        case .registrationSuccessful: return "¡Cuenta creada con éxito!"
        case .emailVerified: return "Email verificado correctamente"
        case .passwordChanged: return "Contraseña cambiada con éxito"
        case .profileUpdated: return "Perfil actualizado con éxito"
        
        // Language Settings
        case .language: return "Idioma"
        case .changeLanguage: return "Cambiar idioma"
        case .spanish: return "Español"
        case .english: return "English"
        case .systemLanguage: return "Idioma del sistema"
        case .languageChanged: return "Idioma cambiado a %@"
        
        // Navigation
        case .home: return "Inicio"
        case .feed: return "Feed"
        case .search: return "Buscar"
        case .create: return "Crear"
        case .marketplace: return "Marketplace"
        case .notifications: return "Notificaciones"
        case .profile: return "Perfil"
        case .settings: return "Configuración"
        
        // Legal Documents
        case .loadingDocument: return "Cargando documento..."
        case .noDocumentAvailable: return "Documento no disponible"
        case .version: return "Versión"
        }
    }
    
    var comment: String {
        switch self {
        case .appName: return "Application name"
        case .acceptedAt: return "Date when terms were accepted - expects formatted date string"
        case .languageChanged: return "Message shown when language is changed - expects language name"
        default: return "Localized string for \(rawValue)"
        }
    }
} 
