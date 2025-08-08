//
//  ProximityPageIndicator.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 8/8/25.
//

import SwiftUI

struct ProximityPageIndicator: View {
    let totalCount: Int
    let currentIndex: Int
    let maxVisibleDots: Int
    let activeColor: Color
    let inactiveColor: Color
    let backgroundOpacity: Double
    let showOnlyWhenMultiple: Bool
    let minimumCountToShow: Int
    
    /// Inicializador principal con todos los parámetros personalizables
    init(
        totalCount: Int,
        currentIndex: Int,
        maxVisibleDots: Int = 5,
        activeColor: Color = .figrBlueAccent,
        inactiveColor: Color = .white,
        backgroundOpacity: Double = 0.2,
        showOnlyWhenMultiple: Bool = true,
        minimumCountToShow: Int = 2
    ) {
        self.totalCount = totalCount
        self.currentIndex = currentIndex
        self.maxVisibleDots = maxVisibleDots
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.backgroundOpacity = backgroundOpacity
        self.showOnlyWhenMultiple = showOnlyWhenMultiple
        self.minimumCountToShow = minimumCountToShow
    }
    
    /// Inicializador conveniente con valores por defecto
    init(totalCount: Int, currentIndex: Int) {
        self.init(
            totalCount: totalCount,
            currentIndex: currentIndex,
            maxVisibleDots: 5,
            activeColor: .figrBlueAccent,
            inactiveColor: .white,
            backgroundOpacity: 0.2,
            showOnlyWhenMultiple: true,
            minimumCountToShow: 2
        )
    }
    
    // MARK: - Computed Properties
    
    /// Determina si se debe mostrar el indicador
    private var shouldShow: Bool {
        if showOnlyWhenMultiple {
            return totalCount >= minimumCountToShow
        }
        return totalCount > 0
    }
    
    /// Calcula el índice central donde siempre estará el punto activo
    private var centerPosition: Int {
        maxVisibleDots / 2
    }
    
    /// Calcula qué puntos mostrar para mantener el activo centrado
    private var visibleDotIndices: [Int] {
        // Si tenemos menos o igual puntos que el máximo visible, mostrar todos
        guard totalCount > maxVisibleDots else {
            return Array(0..<totalCount)
        }
        
        // Calcular el rango de índices a mostrar
        let start = max(0, currentIndex - centerPosition)
        let end = min(totalCount, start + maxVisibleDots)
        
        // Ajustar el inicio si llegamos al final
        let adjustedStart = max(0, end - maxVisibleDots)
        
        return Array(adjustedStart..<end)
    }
    
    // MARK: - Helper Methods
    
    /// Calcula el tamaño del punto basado en su distancia al punto activo
    private func dotSize(for actualIndex: Int) -> CGFloat {
        guard let visualIndex = visibleDotIndices.firstIndex(of: actualIndex) else {
            return 4 // Tamaño por defecto
        }
        
        let activeVisualIndex = visibleDotIndices.firstIndex(of: currentIndex) ?? centerPosition
        let distance = abs(visualIndex - activeVisualIndex)
        
        switch distance {
        case 0: // Punto activo
            return 8
        case 1: // Puntos adyacentes (inmediatamente al lado)
            return 6
        case 2: // Segundo nivel
            return 5
        case 3: // Tercer nivel
            return 4
        default: // Más lejanos
            return 3
        }
    }
    
    /// Calcula la opacidad del punto basado en su distancia al punto activo
    private func dotOpacity(for actualIndex: Int) -> Double {
        guard let visualIndex = visibleDotIndices.firstIndex(of: actualIndex) else {
            return 0.3
        }
        
        let activeVisualIndex = visibleDotIndices.firstIndex(of: currentIndex) ?? centerPosition
        let distance = abs(visualIndex - activeVisualIndex)
        
        if actualIndex == currentIndex {
            return 1.0 // Punto activo completamente opaco
        }
        
        switch distance {
        case 1: // Puntos adyacentes
            return 0.7
        case 2: // Segundo nivel
            return 0.5
        case 3: // Tercer nivel
            return 0.4
        default: // Más lejanos
            return 0.3
        }
    }
    
    /// Calcula el color del punto
    private func dotColor(for actualIndex: Int) -> Color {
        if actualIndex == currentIndex {
            return activeColor
        } else {
            return inactiveColor
        }
    }
    
    // MARK: - Body
    var body: some View {
        if shouldShow {
            VStack {
                Spacer()
                
                HStack(alignment: .center) {
                    Spacer()
                    
                    HStack(spacing: 4) {
                        ForEach(visibleDotIndices, id: \.self) { actualIndex in
                            Circle()
                                .fill(dotColor(for: actualIndex))
                                .frame(
                                    width: dotSize(for: actualIndex),
                                    height: dotSize(for: actualIndex)
                                )
                                .opacity(dotOpacity(for: actualIndex))
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.8),
                                    value: currentIndex
                                )
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: visibleDotIndices)
                    
                    Spacer()
                }
                .padding(.bottom, AppTheme.Padding.medium)
                .background(
                    // Fondo sutil para mejorar la visibilidad
                    Capsule()
                        .fill(Color.black.opacity(backgroundOpacity))
                        .blur(radius: 10)
                        .padding(.horizontal, -18)
                        .padding(.vertical, -8)
                )
            }
        }
    }
}

// MARK: - Extensión para inicializadores de conveniencia
extension ProximityPageIndicator {
    /// Inicializador para usar con arrays
    static func forImages(_ images: [String], currentIndex: Int) -> ProximityPageIndicator {
        ProximityPageIndicator(totalCount: images.count, currentIndex: currentIndex)
    }
    
    /// Inicializador con colores personalizados
    static func withColors(
        totalCount: Int,
        currentIndex: Int,
        activeColor: Color,
        inactiveColor: Color = .white
    ) -> ProximityPageIndicator {
        ProximityPageIndicator(
            totalCount: totalCount,
            currentIndex: currentIndex,
            activeColor: activeColor,
            inactiveColor: inactiveColor
        )
    }
    
    /// Inicializador para siempre mostrar (incluso con 1 punto)
    static func alwaysShow(totalCount: Int, currentIndex: Int) -> ProximityPageIndicator {
        ProximityPageIndicator(
            totalCount: totalCount,
            currentIndex: currentIndex,
            showOnlyWhenMultiple: false,
            minimumCountToShow: 1
        )
    }
    
    /// Inicializador con número mínimo personalizado
    static func withMinimum(
        totalCount: Int,
        currentIndex: Int,
        minimumCountToShow: Int
    ) -> ProximityPageIndicator {
        ProximityPageIndicator(
            totalCount: totalCount,
            currentIndex: currentIndex,
            minimumCountToShow: minimumCountToShow
        )
    }
    
    /// Inicializador para modo oscuro
    static func darkMode(totalCount: Int, currentIndex: Int) -> ProximityPageIndicator {
        ProximityPageIndicator(
            totalCount: totalCount,
            currentIndex: currentIndex,
            activeColor: .figrBlueAccent,
            inactiveColor: .gray,
            backgroundOpacity: 0.4
        )
    }
}

// MARK: - Preview para desarrollo
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 40) {
            // Ejemplo básico
            ProximityPageIndicator(totalCount: 8, currentIndex: 3)
            
            // Ejemplo con colores personalizados
            ProximityPageIndicator.withColors(
                totalCount: 6,
                currentIndex: 2,
                activeColor: .red,
                inactiveColor: .blue
            )
            
            // Ejemplo con solo mostrar cuando hay 3 o más
            ProximityPageIndicator.withMinimum(
                totalCount: 4,
                currentIndex: 1,
                minimumCountToShow: 3
            )
            
            // Ejemplo siempre mostrar
            ProximityPageIndicator.alwaysShow(totalCount: 1, currentIndex: 0)
        }
    }
}
