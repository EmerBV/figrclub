//
//  CreatePostViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation
import Combine

@MainActor
final class CreatePostViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var content = ""
    @Published var selectedCategory: Category?
    @Published var visibility: PostVisibility = .public
    @Published var isPosting = false
    @Published var postCreated = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Private Properties
    private let apiService: APIServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }
    
    // MARK: - Public Methods
    
    func createPost() async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showErrorMessage("El contenido no puede estar vacío")
            return
        }
        
        isPosting = true
        
        let createRequest = CreatePostRequest(
            title: String(content.prefix(50)), // Use first 50 chars as title
            content: content,
            categoryId: selectedCategory?.id,
            visibility: visibility,
            publishNow: true,
            location: nil,
            hashtags: extractHashtags(from: content)
        )
        
        do {
            let _: Post = try await apiService
                .request(endpoint: .createPost, body: createRequest)
                .async()
            
            postCreated = true
            Analytics.shared.logPostCreated(postType: "text")
            
        } catch {
            showErrorMessage("Error al crear post: \(error.localizedDescription)")
            Logger.shared.error("Failed to create post", error: error, category: "create_post")
        }
        
        isPosting = false
    }
    
    private func extractHashtags(from text: String) -> [String] {
        let pattern = #"#\w+"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = regex?.matches(in: text, range: range) ?? []
        
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.hideError()
        }
    }
    
    private func hideError() {
        errorMessage = nil
        showError = false
    }
}
