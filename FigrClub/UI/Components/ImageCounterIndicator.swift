//
//  ImageCounterIndicator.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 8/8/25.
//

import SwiftUI

struct ImageCounterIndicator: View {
    let currentIndex: Int
    let totalCount: Int
    let fontSize: CGFloat
    let textColor: Color
    let backgroundColor: Color
    let backgroundOpacity: Double
    let position: CounterPosition
    let showOnlyWhenMultiple: Bool
    let minimumCountToShow: Int
    
    enum CounterPosition {
        case topTrailing
        case topLeading
        case bottomTrailing
        case bottomLeading
        case custom(EdgeInsets)
        
        var padding: EdgeInsets {
            switch self {
            case .topTrailing:
                return EdgeInsets(top: AppTheme.Padding.medium, leading: 0, bottom: 0, trailing: AppTheme.Padding.medium)
            case .topLeading:
                return EdgeInsets(top: AppTheme.Padding.medium, leading: AppTheme.Padding.medium, bottom: 0, trailing: 0)
            case .bottomTrailing:
                return EdgeInsets(top: 0, leading: 0, bottom: AppTheme.Padding.medium, trailing: AppTheme.Padding.medium)
            case .bottomLeading:
                return EdgeInsets(top: 0, leading: AppTheme.Padding.medium, bottom: AppTheme.Padding.medium, trailing: 0)
            case .custom(let insets):
                return insets
            }
        }
        
        var alignment: Alignment {
            switch self {
            case .topTrailing:
                return .topTrailing
            case .topLeading:
                return .topLeading
            case .bottomTrailing:
                return .bottomTrailing
            case .bottomLeading:
                return .bottomLeading
            case .custom:
                return .topTrailing // Default para custom
            }
        }
    }
    
    /// Inicializador principal con todos los parámetros personalizables
    init(
        currentIndex: Int,
        totalCount: Int,
        fontSize: CGFloat = 12,
        textColor: Color = .white,
        backgroundColor: Color = .black,
        backgroundOpacity: Double = 0.5,
        position: CounterPosition = .topTrailing,
        showOnlyWhenMultiple: Bool = true,
        minimumCountToShow: Int = 2
    ) {
        self.currentIndex = currentIndex
        self.totalCount = totalCount
        self.fontSize = fontSize
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.backgroundOpacity = backgroundOpacity
        self.position = position
        self.showOnlyWhenMultiple = showOnlyWhenMultiple
        self.minimumCountToShow = minimumCountToShow
    }
    
    /// Inicializador conveniente con valores por defecto
    init(currentIndex: Int, totalCount: Int) {
        self.init(
            currentIndex: currentIndex,
            totalCount: totalCount,
            fontSize: 12,
            textColor: .white,
            backgroundColor: .black,
            backgroundOpacity: 0.5,
            position: .topTrailing,
            showOnlyWhenMultiple: true,
            minimumCountToShow: 2
        )
    }
    
    // MARK: - Computed Properties
    
    private var shouldShow: Bool {
        if showOnlyWhenMultiple {
            return totalCount >= minimumCountToShow
        }
        return totalCount > 0
    }
    
    private var counterText: String {
        "\(currentIndex + 1)/\(totalCount)"
    }
    
    // MARK: - Body
    var body: some View {
        if shouldShow {
            VStack {
                if position.alignment == .bottomTrailing || position.alignment == .bottomLeading {
                    Spacer()
                }
                
                HStack {
                    if position.alignment == .topTrailing || position.alignment == .bottomTrailing {
                        Spacer()
                    }
                    
                    Text(counterText)
                        .font(.system(size: fontSize, weight: .medium))
                        .foregroundColor(textColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(backgroundColor.opacity(backgroundOpacity))
                        )
                    
                    if position.alignment == .topLeading || position.alignment == .bottomLeading {
                        Spacer()
                    }
                }
                .padding(position.padding)
                
                if position.alignment == .topTrailing || position.alignment == .topLeading {
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Extensiones para inicializadores de conveniencia
extension ImageCounterIndicator {
    /// Inicializador para usar con arrays
    static func forImages(_ images: [String], currentIndex: Int) -> ImageCounterIndicator {
        ImageCounterIndicator(currentIndex: currentIndex, totalCount: images.count)
    }
    
    /// Inicializador con posición personalizada
    static func withPosition(
        currentIndex: Int,
        totalCount: Int,
        position: CounterPosition
    ) -> ImageCounterIndicator {
        ImageCounterIndicator(
            currentIndex: currentIndex,
            totalCount: totalCount,
            position: position
        )
    }
    
    /// Inicializador con colores personalizados
    static func withColors(
        currentIndex: Int,
        totalCount: Int,
        textColor: Color,
        backgroundColor: Color = .black,
        backgroundOpacity: Double = 0.5
    ) -> ImageCounterIndicator {
        ImageCounterIndicator(
            currentIndex: currentIndex,
            totalCount: totalCount,
            textColor: textColor,
            backgroundColor: backgroundColor,
            backgroundOpacity: backgroundOpacity
        )
    }
    
    /// Inicializador para modo claro
    static func lightMode(currentIndex: Int, totalCount: Int) -> ImageCounterIndicator {
        ImageCounterIndicator(
            currentIndex: currentIndex,
            totalCount: totalCount,
            textColor: .black,
            backgroundColor: .white,
            backgroundOpacity: 0.8
        )
    }
    
    /// Inicializador para siempre mostrar (incluso con 1 imagen)
    static func alwaysShow(currentIndex: Int, totalCount: Int) -> ImageCounterIndicator {
        ImageCounterIndicator(
            currentIndex: currentIndex,
            totalCount: totalCount,
            showOnlyWhenMultiple: false,
            minimumCountToShow: 1
        )
    }
    
    /// Inicializador con tamaño de fuente personalizado
    static func withFontSize(
        currentIndex: Int,
        totalCount: Int,
        fontSize: CGFloat
    ) -> ImageCounterIndicator {
        ImageCounterIndicator(
            currentIndex: currentIndex,
            totalCount: totalCount,
            fontSize: fontSize
        )
    }
    
    /// Inicializador estilo Instagram Stories
    static func storyStyle(currentIndex: Int, totalCount: Int) -> ImageCounterIndicator {
        ImageCounterIndicator(
            currentIndex: currentIndex,
            totalCount: totalCount,
            fontSize: 10,
            textColor: .white,
            backgroundColor: .clear,
            backgroundOpacity: 0,
            position: .topTrailing,
            minimumCountToShow: 2
        )
    }
    
    /// Inicializador para esquina inferior
    static func bottomCorner(currentIndex: Int, totalCount: Int) -> ImageCounterIndicator {
        ImageCounterIndicator(
            currentIndex: currentIndex,
            totalCount: totalCount,
            position: .bottomTrailing
        )
    }
}

// MARK: - Preview para desarrollo
#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        
        VStack(spacing: 20) {
            // Ejemplo básico (esquina superior derecha)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
                    .frame(height: 200)
                
                ImageCounterIndicator(currentIndex: 2, totalCount: 8)
            }
            
            // Ejemplo esquina inferior
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green)
                    .frame(height: 200)
                
                ImageCounterIndicator.bottomCorner(currentIndex: 0, totalCount: 5)
            }
            
            // Ejemplo modo claro
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow)
                    .frame(height: 200)
                
                ImageCounterIndicator.lightMode(currentIndex: 4, totalCount: 10)
            }
        }
        .padding()
    }
}
