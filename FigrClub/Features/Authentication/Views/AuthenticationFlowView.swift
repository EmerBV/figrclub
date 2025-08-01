//
//  AuthenticationFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 3/7/25.
//

import SwiftUI

struct AuthenticationFlowView: View {
    @StateObject private var authViewModel = DependencyInjector.shared.resolve(AuthViewModel.self)
    @StateObject private var errorHandler = DependencyInjector.shared.resolve(GlobalErrorHandler.self)
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentBackgroundColor
                    .ignoresSafeArea()
                
                // Content with explicit transition
                if authViewModel.showEmailVerification {
                    EmailVerificationView(
                        email: authViewModel.registeredEmail,
                        onContinue: {
                            authViewModel.continueFromEmailVerification()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .zIndex(2)
                } else if authViewModel.isShowingLogin {
                    LoginFormView(viewModel: authViewModel, errorHandler: errorHandler)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                        .zIndex(authViewModel.isShowingLogin ? 1 : 0)
                } else {
                    RegisterFormView(viewModel: authViewModel, errorHandler: errorHandler)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .zIndex(authViewModel.isShowingLogin ? 0 : 1)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: authViewModel.isShowingLogin)
            .animation(.easeInOut(duration: 0.4), value: authViewModel.showEmailVerification)
        }
        .onAppear {
            Logger.info("✅ AuthenticationFlowView: Appeared with login state: \(authViewModel.isShowingLogin)")
        }
        .errorAlert(errorHandler: errorHandler)
        .onChange(of: authViewModel.isShowingLogin) { oldValue, newValue in
            Logger.info("🔄 AuthenticationFlowView: Login screen changed from \(oldValue) to \(newValue)")
        }
        .onChange(of: authViewModel.showEmailVerification) { oldValue, newValue in
            Logger.info("🔄 AuthenticationFlowView: Email verification screen changed from \(oldValue) to \(newValue)")
        }
    }
    
    private func retryAuthAction() async {
        if authViewModel.isShowingLogin {
            if let error = await authViewModel.loginWithErrorHandling() {
                errorHandler.handle(error)
            }
        } else {
            if let error = await authViewModel.registerWithErrorHandling() {
                errorHandler.handle(error)
            }
        }
    }
}

