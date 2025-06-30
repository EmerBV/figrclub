//
//  FigrComponents.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import SwiftUI

// MARK: - Spacing
enum Spacing {
    static let xxSmall: CGFloat = 2
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 24
    static let xxLarge: CGFloat = 32
    static let xxxLarge: CGFloat = 48
}

// MARK: - Corner Radius
enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 24
}

// MARK: - Figr Button
struct FigrButton: View {
    enum Style {
        case primary
        case secondary
        case ghost
        case destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .figrPrimary
            case .secondary: return .figrPrimary.opacity(0.1)
            case .ghost: return .clear
            case .destructive: return .figrError
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .figrPrimary
            case .ghost: return .figrPrimary
            case .destructive: return .white
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .primary, .destructive: return nil
            case .secondary: return .figrPrimary.opacity(0.2)
            case .ghost: return .figrBorder
            }
        }
    }
    
    enum Size {
        case small
        case medium
        case large
        
        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 52
            }
        }
        
        var font: Font {
            switch self {
            case .small: return .figrFootnote.weight(.medium)
            case .medium: return .figrCallout.weight(.medium)
            case .large: return .figrBody.weight(.medium)
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            case .medium: return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
            case .large: return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
            }
        }
    }
    
    let title: String
    let style: Style
    let size: Size
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    init(
        title: String,
        style: Style = .primary,
        size: Size = .medium,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.small) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else {
                    Text(title)
                        .font(size.font)
                        .foregroundColor(style.foregroundColor)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(style.backgroundColor)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(style.borderColor ?? Color.clear, lineWidth: 1)
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

// MARK: - Figr Text Field
struct FigrTextField: View {
    enum Style {
        case `default`
        case rounded
        case underlined
    }
    
    let title: String
    let placeholder: String?
    @Binding var text: String
    let isSecure: Bool
    let validation: ValidationState?
    let style: Style
    let leadingIcon: String?
    let trailingIcon: String?
    let onTrailingIconTap: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    @State private var isSecureVisible = false
    
    init(
        title: String,
        placeholder: String? = nil,
        text: Binding<String>,
        isSecure: Bool = false,
        validation: ValidationState? = nil,
        style: Style = .default,
        leadingIcon: String? = nil,
        trailingIcon: String? = nil,
        onTrailingIconTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.validation = validation
        self.style = style
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.onTrailingIconTap = onTrailingIconTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            // Title
            Text(title)
                .font(.figrSubheadline)
                .foregroundColor(.figrTextSecondary)
            
            // Input Field
            HStack(spacing: Spacing.medium) {
                // Leading Icon
                if let leadingIcon = leadingIcon {
                    Image(systemName: leadingIcon)
                        .foregroundColor(.figrTextSecondary)
                        .frame(width: 20, height: 20)
                }
                
                // Text Input
                if isSecure && !isSecureVisible {
                    SecureField(placeholder ?? title, text: $text)
                        .focused($isFocused)
                        .textFieldStyle(FigrTextFieldStyle(style: style, isFocused: isFocused, validation: validation))
                } else {
                    TextField(placeholder ?? title, text: $text)
                        .focused($isFocused)
                        .textFieldStyle(FigrTextFieldStyle(style: style, isFocused: isFocused, validation: validation))
                }
                
                // Security Toggle
                if isSecure {
                    Button(action: { isSecureVisible.toggle() }) {
                        Image(systemName: isSecureVisible ? "eye.slash" : "eye")
                            .foregroundColor(.figrTextSecondary)
                            .frame(width: 20, height: 20)
                    }
                }
                
                // Trailing Icon
                if let trailingIcon = trailingIcon {
                    Button(action: { onTrailingIconTap?() }) {
                        Image(systemName: trailingIcon)
                            .foregroundColor(.figrTextSecondary)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .padding(.horizontal, Spacing.large)
            .frame(height: 48)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(style == .rounded ? CornerRadius.medium : 0)
            
            // Validation Message
            if let validation = validation,
               case .invalid(let message) = validation {
                HStack(spacing: Spacing.small) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.figrError)
                        .font(.figrCaption)
                    
                    Text(message)
                        .font(.figrCaption)
                        .foregroundColor(.figrError)
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .default, .rounded:
            return .figrSurface
        case .underlined:
            return .clear
        }
    }
    
    private var borderColor: Color {
        if let validation = validation {
            switch validation {
            case .valid:
                return .figrSuccess
            case .invalid:
                return .figrError
            case .idle:
                return isFocused ? .figrPrimary : .figrBorder
            }
        }
        return isFocused ? .figrPrimary : .figrBorder
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .default, .rounded:
            return 1
        case .underlined:
            return 0
        }
    }
}

// MARK: - Custom Text Field Style
struct FigrTextFieldStyle: TextFieldStyle {
    let style: FigrTextField.Style
    let isFocused: Bool
    let validation: ValidationState?
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.figrBody)
            .foregroundColor(.figrTextPrimary)
    }
}

// MARK: - Figr Card
struct FigrCard<Content: View>: View {
    let content: Content
    let padding: EdgeInsets
    let backgroundColor: Color
    let shadowRadius: CGFloat
    let cornerRadius: CGFloat
    
    init(
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        backgroundColor: Color = .figrSurface,
        shadowRadius: CGFloat = 2,
        cornerRadius: CGFloat = CornerRadius.medium,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.shadowRadius = shadowRadius
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 1)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: Spacing.large) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .figrPrimary))
            
            if let message = message {
                Text(message)
                    .font(.figrBody)
                    .foregroundColor(.figrTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.figrBackground)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void
    
    init(
        title: String = "Algo salió mal",
        message: String,
        buttonTitle: String = "Reintentar",
        action: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Spacing.xLarge) {
            VStack(spacing: Spacing.medium) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.figrError)
                
                Text(title)
                    .font(.figrTitle3)
                    .foregroundColor(.figrTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.figrBody)
                    .foregroundColor(.figrTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            FigrButton(title: buttonTitle, action: action)
                .frame(maxWidth: 200)
        }
        .padding(.horizontal, Spacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.figrBackground)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let title: String
    let message: String
    let imageName: String
    let buttonTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        message: String,
        imageName: String = "tray",
        buttonTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.imageName = imageName
        self.buttonTitle = buttonTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Spacing.xLarge) {
            VStack(spacing: Spacing.medium) {
                Image(systemName: imageName)
                    .font(.system(size: 48))
                    .foregroundColor(.figrTextSecondary)
                
                Text(title)
                    .font(.figrTitle3)
                    .foregroundColor(.figrTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.figrBody)
                    .foregroundColor(.figrTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let buttonTitle = buttonTitle, let action = action {
                FigrButton(title: buttonTitle, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding(.horizontal, Spacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.figrBackground)
    }
}

// MARK: - Figr Avatar
struct FigrAvatar: View {
    let imageURL: String?
    let size: CGFloat
    let fallbackText: String
    
    init(imageURL: String?, size: CGFloat = 40, fallbackText: String = "?") {
        self.imageURL = imageURL
        self.size = size
        self.fallbackText = fallbackText
    }
    
    var body: some View {
        AsyncImage(url: URL(string: imageURL ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ZStack {
                Circle()
                    .fill(.figrPrimary.opacity(0.1))
                
                Text(fallbackText)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(.figrPrimary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Figr Badge
struct FigrBadge: View {
    let text: String
    let style: BadgeStyle
    
    enum BadgeStyle {
        case primary
        case secondary
        case success
        case warning
        case error
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .figrPrimary
            case .secondary: return .figrSecondary
            case .success: return .figrSuccess
            case .warning: return .figrWarning
            case .error: return .figrError
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .secondary, .success, .error: return .white
            case .warning: return .black
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(.figrCaption.weight(.medium))
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xxSmall)
            .background(style.backgroundColor)
            .cornerRadius(CornerRadius.small)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct ToastView<T: View>: View {
    @Binding var isPresented: Bool
    let content: T
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> T) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        if isPresented {
            VStack {
                Spacer()
                
                content
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(CornerRadius.medium)
                    .shadow(radius: 4)
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                isPresented = false
                            }
                        }
                    }
            }
            .animation(.spring(), value: isPresented)
        }
    }
}

// MARK: - Preview Helpers
#if DEBUG
struct FigrComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.xLarge) {
                // Buttons
                VStack(spacing: Spacing.medium) {
                    FigrButton(title: "Primary Button", style: .primary) { }
                    FigrButton(title: "Secondary Button", style: .secondary) { }
                    FigrButton(title: "Ghost Button", style: .ghost) { }
                    FigrButton(title: "Loading...", style: .primary, isLoading: true) { }
                }
                
                // Text Fields
                VStack(spacing: Spacing.medium) {
                    FigrTextField(title: "Email", text: .constant(""))
                    FigrTextField(title: "Password", text: .constant(""), isSecure: true)
                    FigrTextField(title: "Search", text: .constant(""), leadingIcon: "magnifyingglass")
                }
                
                // Cards
                FigrCard {
                    VStack {
                        Text("Card Title")
                            .font(.figrHeadline)
                        Text("Card content goes here")
                            .font(.figrBody)
                    }
                }
                
                // Avatar and Badge
                HStack {
                    FigrAvatar(imageURL: nil, fallbackText: "JD")
                    FigrBadge(text: "New", style: .primary)
                    FigrBadge(text: "Hot", style: .error)
                }
            }
            .padding()
        }
        .background(.figrBackground)
    }
}
#endifPrimary = Color("FigrPrimary")
    static let figrSecondary = Color("FigrSecondary")
    static let figrAccent = Color("FigrAccent")
    static let figrBackground = Color("FigrBackground")
    static let figrSurface = Color("FigrSurface")
    static let figrError = Color("FigrError")
    static let figrSuccess = Color("FigrSuccess")
    static let figrWarning = Color("FigrWarning")
    static let figrTextPrimary = Color("FigrTextPrimary")
    static let figrTextSecondary = Color("FigrTextSecondary")
    static let figrBorder = Color("FigrBorder")
}

