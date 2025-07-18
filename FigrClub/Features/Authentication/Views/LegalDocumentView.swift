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
    private func documentContentView(_ document: LegalDocumentData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Document Content (HTML)
            SelfSizingWebView(htmlContent: document.htmlContent)
                .frame(height: 800) // Fixed height for now
            
            // Debug: Show raw content if needed
#if DEBUG
            Text("Debug: Content length: \(document.htmlContent.count) chars")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
#endif
            
        }
        .padding(.horizontal, 16)
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

// MARK: - Self-Sizing Web View
struct SelfSizingWebView: UIViewRepresentable {
    let htmlContent: String
    @State private var webViewHeight: CGFloat = 400
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.dataDetectorTypes = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear
        
        // Enable debugging
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Add logging to debug
        Logger.debug("📄 HTMLContentView: Loading HTML content with \(htmlContent.count) characters")
        
        let styledHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    font-size: 16px;
                    line-height: 1.6;
                    color: #333333;
                    margin: 0;
                    padding: 16px;
                    background-color: transparent;
                    word-wrap: break-word;
                    overflow-wrap: break-word;
                }
                h1, h2, h3, h4, h5, h6 {
                    color: #1a1a1a;
                    margin-top: 24px;
                    margin-bottom: 12px;
                    font-weight: 600;
                }
                h1 { font-size: 24px; }
                h2 { font-size: 20px; }
                h3 { font-size: 18px; }
                p {
                    margin-bottom: 12px;
                    margin-top: 0;
                }
                ul, ol {
                    margin: 12px 0;
                    padding-left: 24px;
                }
                li {
                    margin-bottom: 6px;
                }
                @media (prefers-color-scheme: dark) {
                    body { 
                        color: #ffffff; 
                        background-color: transparent;
                    }
                    h1, h2, h3, h4, h5, h6 { 
                        color: #ffffff; 
                    }
                }
            </style>
        </head>
        <body>
            \(htmlContent)
            <script>
                // Notify when content is loaded
                document.addEventListener('DOMContentLoaded', function() {
                    console.log('HTML content loaded successfully');
                });
            </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(styledHTML, baseURL: nil)
        Logger.debug("📄 HTMLContentView: HTML string loaded into WebView")
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: SelfSizingWebView
        
        init(_ parent: SelfSizingWebView) {
            self.parent = parent
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Only allow the initial load
            if navigationAction.navigationType == .other {
                Logger.debug("📄 WebView: Allowing navigation for initial load")
                decisionHandler(.allow)
            } else {
                Logger.debug("📄 WebView: Cancelling navigation of type: \(navigationAction.navigationType.rawValue)")
                decisionHandler(.cancel)
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Logger.debug("📄 WebView: Finished loading navigation")
            
            // Calculate content height and update parent
            webView.evaluateJavaScript("document.body.scrollHeight") { result, error in
                DispatchQueue.main.async {
                    if let height = result as? CGFloat {
                        Logger.debug("📄 WebView: Content height calculated: \(height)")
                        self.parent.webViewHeight = max(height, 400) // Minimum 400px
                    } else if let error = error {
                        Logger.error("📄 WebView: Error calculating height: \(error.localizedDescription)")
                        self.parent.webViewHeight = 400 // Fallback height
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Logger.error("📄 WebView: Failed loading with error: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Logger.error("📄 WebView: Failed provisional navigation with error: \(error.localizedDescription)")
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
