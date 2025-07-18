//
//  LegalDocumentView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import SwiftUI
import WebKit

struct LegalDocumentView: View {
    @ObservedObject var viewModel: LegalDocumentViewModel
    @ObservedObject var errorHandler: GlobalErrorHandler
    @Environment(\.localizationManager) private var localizationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                } else if let document = viewModel.document {
                    documentContentView(document)
                } else {
                    emptyView
                }
            }
            .navigationTitle(getNavigationTitle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .task {
            await loadDocumentIfNeeded()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            EBVLoadingView()
            
            Text(localizationManager.localizedString(for: .loadingDocument))
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text(localizationManager.localizedString(for: .error))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Reintentar") {
                Task {
                    await viewModel.retryLoading()
                }
            }
            .buttonStyle(EBVPrimaryBtnStyle())
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Document Content View
    private func documentContentView(_ document: LegalDocument) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Document Header
                documentHeaderView(document)
                
                // Document Content (HTML)
                HTMLContentView(htmlContent: document.htmlContent)
                    .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Document Header
    private func documentHeaderView(_ document: LegalDocument) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(document.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            if !document.summary.isEmpty {
                Text(document.summary)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(localizationManager.localizedString(for: .version))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(document.version)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let effectiveDate = document.formattedEffectiveDate {
                    Text(DateFormatter.localizedString(from: effectiveDate, dateStyle: .medium, timeStyle: .none))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(localizationManager.localizedString(for: .noDocumentAvailable))
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    private func getNavigationTitle() -> String {
        if let document = viewModel.document {
            return document.title
        }
        
        // Fallback title based on document type
        switch viewModel.documentType {
        case .termsOfService:
            return localizationManager.localizedString(for: .termsAndConditions)
        case .privacyPolicy:
            return localizationManager.localizedString(for: .privacyPolicy)
        }
    }
    
    private func loadDocumentIfNeeded() async {
        if viewModel.document == nil && !viewModel.isLoading {
            await viewModel.loadDocument()
        }
    }
}

// MARK: - HTML Content View
struct HTMLContentView: UIViewRepresentable {
    let htmlContent: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        
        // Configure for better text rendering
        let configuration = webView.configuration
        configuration.dataDetectorTypes = []
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let styledHTML = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    font-size: 16px;
                    line-height: 1.6;
                    color: #333;
                    margin: 0;
                    padding: 16px;
                    background-color: transparent;
                }
                h1, h2, h3 {
                    color: #1a1a1a;
                    margin-top: 24px;
                    margin-bottom: 12px;
                }
                h1 { font-size: 24px; }
                h2 { font-size: 20px; }
                h3 { font-size: 18px; }
                p {
                    margin-bottom: 12px;
                }
                @media (prefers-color-scheme: dark) {
                    body { color: #ffffff; }
                    h1, h2, h3 { color: #ffffff; }
                }
            </style>
        </head>
        <body>
            \(htmlContent)
        </body>
        </html>
        """
        
        webView.loadHTMLString(styledHTML, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Only allow the initial load
            if navigationAction.navigationType == .other {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
            }
        }
    }
}

// MARK: - Factory Methods
extension LegalDocumentView {
    static func termsOfService(errorHandler: GlobalErrorHandler) -> LegalDocumentView {
        let countryCode = getCurrentCountryCode()
        let viewModel = LegalDocumentViewModel.termsOfService(countryCode: countryCode)
        return LegalDocumentView(viewModel: viewModel, errorHandler: errorHandler)
    }
    
    static func privacyPolicy(errorHandler: GlobalErrorHandler) -> LegalDocumentView {
        let countryCode = getCurrentCountryCode()
        let viewModel = LegalDocumentViewModel.privacyPolicy(countryCode: countryCode)
        return LegalDocumentView(viewModel: viewModel, errorHandler: errorHandler)
    }
    
    private static func getCurrentCountryCode() -> String {
        // Get country code from current locale, fallback to ES for Spanish or US for English
        if let regionCode = Locale.current.region?.identifier {
            return regionCode
        }
        
        // Fallback based on language
        let languageCode = Locale.current.language.languageCode?.identifier ?? "es"
        return languageCode == "en" ? "US" : "ES"
    }
} 