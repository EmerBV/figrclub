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
    case or = "or"
    
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
    case username = "username"
    case fullName = "full_name"
    case firstName = "first_name"
    case lastName = "last_name"
    case emailPlaceholder = "email_placeholder"
    case passwordPlaceholder = "password_placeholder"
    case confirmPassword = "confirm_password"
    case createPasswordPlaceholder = "create_password_placeholder"
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
    case legalDocuments = "legal_documents"
    case acceptTerms = "accept_terms"
    case termsAndConditions = "terms_and_conditions"
    case privacyPolicy = "privacy_policy"
    case legalDocumentsDescription = "legal_documents_description"
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
    
    // MARK: - Marketplace
    case searchTextfield = "search_textfield"
    case featuredString = "featured_string"
    case seeAllString = "see_all_string"
    case allProductsString = "all_products_string"
    case numberOfProducts = "number_of_products"
    case categoryString = "category_string"
    case applyFilterString = "apply_filter_string"
    case clearFilterString = "clear_filter_string"
    case filtersString = "filters_string"
    
    // MARK: - Product Categories
    case categoryAll = "category_all"
    case categoryAnime = "category_anime"
    case categoryManga = "category_manga"
    case categoryGaming = "category_gaming"
    case categoryMovies = "category_movies"
    case categoryTv = "category_tv"
    case categoryCollectibles = "category_collectibles"
    case categoryVintage = "category_vintage"
    
    // MARK: - Logout Alert Confirmation
    case areYouSureToLogout = "are_you_sure_to_logout"
    
    // MARK: - Feed
    case yourStoryString = "your_story_string"
    case likesString = "likes_string"
    case seeAllComments = "see_all_comments"
    
    // MARK: - Create
    case createPost = "create_post"
    case createStory = "create_story"
    case createReel = "create_reel"
    case createLiveStream = "create_live_stream"
    case cameraPermissionRequired = "camera_permission_required"
    case goToSettings = "go_to_settings"
    case cameraPermissionSettingsDescription = "camera_permission_settings_description"
    case tapToAllowCameraPermission = "tap_to_allow_camera_permission"
    case settingUpCamera = "setting_up_camera"
    case shareWithFollowers = "share_with_followers"
    case videoPreview = "video_preview"
    case recentString = "recent_string"
    case photoGallery = "photo_gallery"
    
    // MARK: - Notifications
    case messagesString = "messages_string"
    case notificationsString = "notifications_string"
    case unreadString = "unread_string"
    
    // MARK: - Profile
    case inFigrClubSince = "in_figrclub_since"
    case contentString = "content_string"
    case myPostsString = "my_posts_string"
    case myStoriesString = "my_stories_string"
    case myReelsString = "my_reels_string"
    case myLiveStreamsString = "my_live_streams_string"
    case transactionsString = "transactions_string"
    case shoppingsString = "shoppings_string"
    case salesString = "sales_string"
    case shippingString = "shipping_string"
    case accountString = "account_string"
    case favoritesString = "favorites_string"
    case seeLocationString = "see_location_string"
    case onSaleTab = "on_sale_tab"
    case reviewsTab = "reviews_tab"
    case infoTab = "info_tab"
    case basedOnString = "based_on_string"
    case profileInfo = "profile_info"
    case memberSince = "member_since"
    case lastActivity = "last_activity"
    case locationString = "location_string"
    case notSpecified = "not_specified"
    case salesStatistics = "sales_statistics"
    case productsSold = "products_sold"
    case activeProducts = "active_products"
    case averageRating = "average_rating"
    case returnPolicy = "return_policy"
    case returnPolicyDescription = "return_policy_description"
    case contactButton = "contact_button"
    case highlightItNow = "highlight_it_now"
    case inactiveString = "inactive_string"
    
    
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
        case .or: return "o"
            
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
        case .username: return "Nombre de usuario"
        case .fullName: return "Nombre completo"
        case .firstName: return "Nombre"
        case .lastName: return "Apellido"
        case .emailPlaceholder: return "Introduce tu correo"
        case .passwordPlaceholder: return "Introduce tu contraseña"
        case .confirmPassword: return "Confirmar contraseña"
        case .createPasswordPlaceholder: return "Crea una contraseña"
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
        case .legalDocuments: return "Documentos legales"
        case .acceptTerms: return "Acepto los términos y condiciones y la política de privacidad"
        case .termsAndConditions: return "términos y condiciones"
        case .privacyPolicy: return "política de privacidad"
        case .legalDocumentsDescription: return "He leído y acepto los documentos legales anteriores."
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
            
            // Marketplace
        case .searchTextfield: return "Buscar figuras, colecciones..."
        case .featuredString: return "Destacados"
        case .seeAllString: return "Ver todo"
        case .allProductsString: return "Todos los productos"
        case .numberOfProducts: return "%d productos"
        case .categoryString: return "Categoría"
        case .applyFilterString: return "Aplicar filtro"
        case .clearFilterString: return "Limpiar filtro"
        case .filtersString: return "Filtros"
            
            // Product Categories
        case .categoryAll: return "Todos"
        case .categoryAnime: return "Anime"
        case .categoryManga: return "Manga"
        case .categoryGaming: return "Gaming"
        case .categoryMovies: return "Películas"
        case .categoryTv: return "TV/Series"
        case .categoryCollectibles: return "Coleccionables"
        case .categoryVintage: return "Vintage"
            
            // Logout Alert Confirmation
        case .areYouSureToLogout: return "¿Estás seguro de que quieres cerrar tu sesión?"
            
            // Feed
        case .yourStoryString: return "Tu historia"
        case .likesString: return "%d me gusta"
        case .seeAllComments: return "Ver los %d comentarios"
            
            // Create
        case .createPost: return "PUBLICACIÓN"
        case .createStory: return "HISTORIA"
        case .createReel: return "REEL"
        case .createLiveStream: return "EN DIRECTO"
        case .cameraPermissionRequired: return "Permiso de cámara requerido"
        case .goToSettings: return "Ir a Configuración"
        case .cameraPermissionSettingsDescription: return "Para usar la cámara, ve a Configuración > Privacidad y Seguridad > Cámara y activa el permiso para FigrClub."
        case .tapToAllowCameraPermission: return "Toca para permitir acceso a la cámara"
        case .settingUpCamera: return "Configurando cámara..."
        case .shareWithFollowers: return " Compartir con Seguidores"
        case .videoPreview: return "Previsualización del video"
        case .recentString: return "Recientes"
        case .photoGallery: return "Galería de fotos"
            
            // Notifications
        case .messagesString: return "Mensajes"
        case .notificationsString: return "Notificaciones"
        case .unreadString: return "No leído"
            
            // Profile
        case .inFigrClubSince: return "En FigrClub desde %@"
        case .contentString: return "Contenido"
        case .myPostsString: return "Mis Posts"
        case .myStoriesString: return "Mis Histories"
        case .myReelsString: return "Mis Reels"
        case .myLiveStreamsString: return "Mis Directos"
        case .transactionsString: return "Transacciones"
        case .shoppingsString: return "Compras"
        case .salesString: return "Ventas"
        case .shippingString: return "Envíos"
        case .accountString: return "Cuenta"
        case .favoritesString: return "Favoritos"
        case .seeLocationString: return "Ver ubicación"
        case .onSaleTab: return "En venta"
        case .reviewsTab: return "Valoraciones"
        case .infoTab: return "Info"
        case .basedOnString: return "Basado en %d valoraciones"
        case .profileInfo: return "Información de perfil"
        case .memberSince: return "Miembro desde"
        case .lastActivity: return "Última actividad"
        case .locationString: return "Ubicación"
        case .notSpecified: return "No especificada"
        case .salesStatistics: return "Estadísticas de venta"
        case .productsSold: return "Productos vendidos"
        case .activeProducts: return "Productos activos"
        case .averageRating: return "Valoración promedio"
        case .returnPolicy: return "Política de devoluciones"
        case .returnPolicyDescription: return "Este vendedor acepta devoluciones dentro de los 7 días posteriores a la recepción del producto, siempre que esté en las mismas condiciones."
        case .contactButton: return "Contactar"
        case .highlightItNow: return "Destácalo ya"
        case .inactiveString: return "Inactivo"
        
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
