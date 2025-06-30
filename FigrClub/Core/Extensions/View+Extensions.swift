//
//  View+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import SwiftUI

extension View {
    /// Applies a conditional modifier
    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Applies a conditional modifier with else clause
    @ViewBuilder
    func `if`<T: View, U: View>(
        _ condition: Bool,
        transform: (Self) -> T,
        else elseTransform: (Self) -> U
    ) -> some View {
        if condition {
            transform(self)
        } else {
            elseTransform(self)
        }
    }
    
    /// Hides the view based on condition
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }
    
    /// Adds a corner radius to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    /// Adds a shadow with default values
    func defaultShadow() -> some View {
        self.shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    /// Adds haptic feedback on tap
    func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
    
    /// Adds a toast overlay
    func toast<T: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> T
    ) -> some View {
        self.overlay(
            ToastView(isPresented: isPresented, content: content)
        )
    }
    
    /// Keyboard dismiss on tap
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil)
        }
    }
    
    /// Navigation bar styling
    func navigationBarStyle(
        backgroundColor: Color = .figrBackground,
        titleColor: Color = .figrTextPrimary
    ) -> some View {
        self.onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(backgroundColor)
            appearance.titleTextAttributes = [.foregroundColor: UIColor(titleColor)]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(titleColor)]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    
}

#if DEBUG
extension View {
    func debugPrint(_ value: Any) -> some View {
        print("🐛 Debug: \(value)")
        return self
    }
    
    func debugBackground(_ color: Color = .red) -> some View {
        self.background(color.opacity(0.3))
    }
    
    func debugBorder(_ color: Color = .red, width: CGFloat = 1) -> some View {
        self.overlay(
            Rectangle()
                .stroke(color, lineWidth: width)
        )
    }
}

struct DebugInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🏗️ Debug Info")
                .font(.figrCaption.bold())
            Text("Environment: \(AppConfig.Environment.current.displayName)")
            Text("Version: \(AppConfig.AppInfo.version)")
            Text("Build: \(AppConfig.AppInfo.buildNumber)")
            Text("API: \(AppConfig.API.baseURL)")
        }
        .font(.figrCaption2)
        .padding(8)
        .background(.black.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(8)
    }
}
#endif
