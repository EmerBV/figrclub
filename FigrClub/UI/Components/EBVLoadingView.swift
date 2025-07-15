//
//  EBVLoadingView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import SwiftUI

// MARK: - Loading Message Configuration
enum LoadingMessage {
    case figrClub
    case login
    case logout
    case register
    case dataSync
    case custom(String)
    
    var text: String {
        switch self {
        case .figrClub:
            return "Cargando FigrClub..."
        case .login:
            return "Iniciando sesión..."
        case .logout:
            return "Cerrando sesión..."
        case .register:
            return "Creando cuenta..."
        case .dataSync:
            return "Sincronizando datos..."
        case .custom(let message):
            return message
        }
    }
    
    var icon: String? {
        switch self {
        case .figrClub:
            return "app.fill"
        case .login:
            return "person.circle.fill"
        case .logout:
            return "rectangle.portrait.and.arrow.right"
        case .register:
            return "person.badge.plus"
        case .dataSync:
            return "arrow.triangle.2.circlepath"
        case .custom:
            return nil
        }
    }
}

// MARK: - Loading View Component
struct EBVLoadingView: View {
    // MARK: - Properties
    let message: LoadingMessage
    let showIcon: Bool
    let backgroundColor: Color
    let progressColor: Color
    let textColor: Color
    
    // MARK: - Initializers
    
    /// Inicializador principal con configuración completa
    init(
        message: LoadingMessage = .figrClub,
        showIcon: Bool = false,
        backgroundColor: Color = Color(.systemBackground),
        progressColor: Color = .blue,
        textColor: Color = .secondary
    ) {
        self.message = message
        self.showIcon = showIcon
        self.backgroundColor = backgroundColor
        self.progressColor = progressColor
        self.textColor = textColor
    }
    
    /// Inicializador conveniente para mensajes predeterminados
    init(_ predefinedMessage: LoadingMessage) {
        self.init(message: predefinedMessage, showIcon: true)
    }
    
    /// Inicializador conveniente para mensajes personalizados
    init(customMessage: String, showIcon: Bool = false) {
        self.init(
            message: .custom(customMessage),
            showIcon: showIcon
        )
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.large) {
                // Progress View
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: progressColor))
                    .scaleEffect(1.5)
                
                // Content Container
                VStack(spacing: showIcon ? Spacing.small : 0) {
                    // Optional Icon
                    if showIcon, let iconName = message.icon {
                        Image(systemName: iconName)
                            .font(.title2)
                            .foregroundColor(progressColor)
                    }
                    
                    // Loading Text
                    Text(message.text)
                        .font(.headline)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

// MARK: - Convenience Extensions
extension EBVLoadingView {
    /// Loading para el inicio de la app
    static var appLaunch: EBVLoadingView {
        EBVLoadingView(.figrClub)
    }
    
    /// Loading para autenticación - login
    static var login: EBVLoadingView {
        EBVLoadingView(.login)
    }
    
    /// Loading para logout
    static var logout: EBVLoadingView {
        EBVLoadingView(.logout)
    }
    
    /// Loading para registro
    static var register: EBVLoadingView {
        EBVLoadingView(.register)
    }
    
    /// Loading para sincronización de datos
    static var dataSync: EBVLoadingView {
        EBVLoadingView(.dataSync)
    }
    
    /// Loading personalizado con mensaje específico
    static func custom(_ message: String, showIcon: Bool = false) -> EBVLoadingView {
        EBVLoadingView(customMessage: message, showIcon: showIcon)
    }
}

// MARK: - Modifier for Easy Usage
struct LoadingViewModifier: ViewModifier {
    let isLoading: Bool
    let message: LoadingMessage
    let showIcon: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 2 : 0)
            
            if isLoading {
                EBVLoadingView(
                    message: message,
                    showIcon: showIcon,
                    backgroundColor: Color.black.opacity(0.3)
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: isLoading)
            }
        }
    }
}

extension View {
    /// Muestra un loading overlay sobre la vista actual
    func loadingOverlay(
        isLoading: Bool,
        message: LoadingMessage = .figrClub,
        showIcon: Bool = false
    ) -> some View {
        modifier(LoadingViewModifier(
            isLoading: isLoading,
            message: message,
            showIcon: showIcon
        ))
    }
}

// MARK: - Preview Provider
#if DEBUG
struct EBVLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Ejemplo básico
            EBVLoadingView()
                .previewDisplayName("Default")
            
            // Ejemplo con login
            EBVLoadingView.login
                .previewDisplayName("Login")
            
            // Ejemplo con logout
            EBVLoadingView.logout
                .previewDisplayName("Logout")
            
            // Ejemplo personalizado
            EBVLoadingView.custom("Procesando datos...", showIcon: true)
                .previewDisplayName("Custom")
            
            // Ejemplo con overlay
            VStack {
                Text("Contenido de la app")
                Button("Test") { }
            }
            .loadingOverlay(isLoading: true, message: .login, showIcon: true)
            .previewDisplayName("Overlay")
        }
    }
}
#endif
