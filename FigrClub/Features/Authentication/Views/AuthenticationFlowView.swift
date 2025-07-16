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
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                // Content with explicit transition
                if authViewModel.isShowingLogin {
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
        }
        .onAppear {
            Logger.info("✅ AuthenticationFlowView: Appeared with login state: \(authViewModel.isShowingLogin)")
        }
        .errorAlert(errorHandler: errorHandler)
        .onChange(of: authViewModel.isShowingLogin) { oldValue, newValue in
            Logger.info("🔄 AuthenticationFlowView: Screen changed from \(oldValue) to \(newValue)")
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

// MARK: - Preview
/*
#if DEBUG
struct AuthenticationFlowView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationFlowView()
            .environmentObject(DependencyInjector.shared.resolve(AuthStateManager.self))
    }
}
#endif
 */


