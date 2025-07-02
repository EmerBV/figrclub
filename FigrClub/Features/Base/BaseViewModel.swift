//
//  BaseViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 2/7/25.
//

import Foundation
import Combine

// MARK: - Error Handling Protocol
protocol ErrorHandling: ObservableObject {
    var errorMessage: String? { get set }
    var showError: Bool { get set }
    
    func showErrorMessage(_ message: String)
    func hideError()
}

// MARK: - Loading State Protocol
protocol LoadingStateManaging: ObservableObject {
    var isLoading: Bool { get set }
    var isLoadingMore: Bool { get set }
}

// MARK: - View State Enum
enum ViewState<T> {
    case idle
    case loading
    case loaded(T)
    case error(String)
    case loadingMore(T) // For pagination
    
    var isLoading: Bool {
        switch self {
        case .loading: return true
        default: return false
        }
    }
    
    var isLoadingMore: Bool {
        switch self {
        case .loadingMore: return true
        default: return false
        }
    }
    
    var data: T? {
        switch self {
        case .loaded(let data), .loadingMore(let data):
            return data
        default:
            return nil
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .error(let message):
            return message
        default:
            return nil
        }
    }
}

// MARK: - Base ViewModel
@MainActor
class BaseViewModel: ObservableObject, ErrorHandling, LoadingStateManaging {
    
    // MARK: - Published Properties
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var isLoading = false
    @Published var isLoadingMore = false
    
    // MARK: - Private Properties
    private var errorTimer: Timer?
    protected var cancellables = Set<AnyCancellable>()
    
    // MARK: - Error Handling
    func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        // Auto-hide after 3 seconds
        errorTimer?.invalidate()
        errorTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.hideError()
            }
        }
        
        Logger.shared.error("ViewModel Error: \(message)", category: "viewmodel")
    }
    
    func hideError() {
        errorMessage = nil
        showError = false
        errorTimer?.invalidate()
        errorTimer = nil
    }
    
    // MARK: - Loading State Management
    func setLoadingState(_ loading: Bool) {
        isLoading = loading
    }
    
    func setLoadingMoreState(_ loadingMore: Bool) {
        isLoadingMore = loadingMore
    }
    
    // MARK: - Lifecycle
    deinit {
        errorTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - Paginated ViewModel Base
@MainActor
class PaginatedViewModel<T>: BaseViewModel {
    
    // MARK: - Published Properties
    @Published var items: [T] = []
    @Published var currentPage = 0
    @Published var hasMorePages = true
    
    // MARK: - Protected Properties
    protected let pageSize: Int
    
    // MARK: - Initialization
    init(pageSize: Int = AppConfig.Pagination.defaultPageSize) {
        self.pageSize = pageSize
        super.init()
    }
    
    // MARK: - Pagination Methods
    func resetPagination() {
        currentPage = 0
        hasMorePages = true
        items.removeAll()
    }
    
    func updatePagination(from response: PaginatedResponse<T>) {
        currentPage = response.page
        hasMorePages = !response.last
    }
    
    func appendItems(_ newItems: [T], from response: PaginatedResponse<T>) where T: Identifiable, T.ID: Hashable {
        // Remove duplicates based on ID
        let existingIds = Set(items.map { $0.id })
        let filteredNewItems = newItems.filter { !existingIds.contains($0.id) }
        
        items.append(contentsOf: filteredNewItems)
        updatePagination(from: response)
        
        if filteredNewItems.count != newItems.count {
            Logger.shared.warning("Filtered out \(newItems.count - filteredNewItems.count) duplicate items", category: "pagination")
        }
    }
    
    func replaceItems(_ newItems: [T], from response: PaginatedResponse<T>) {
        items = newItems
        updatePagination(from: response)
    }
    
    // MARK: - Abstract Methods (Override in subclasses)
    func loadFirstPage() async {
        fatalError("loadFirstPage() must be overridden in subclass")
    }
    
    func loadNextPage() async {
        fatalError("loadNextPage() must be overridden in subclass")
    }
    
    // MARK: - Public Methods
    func refresh() async {
        resetPagination()
        await loadFirstPage()
    }
    
    func loadMore() async {
        guard !isLoadingMore && hasMorePages else { return }
        await loadNextPage()
    }
}

// MARK: - Search ViewModel Base
@MainActor
class SearchableViewModel<T>: PaginatedViewModel<T> {
    
    // MARK: - Published Properties
    @Published var searchText = ""
    @Published var isSearching = false
    
    // MARK: - Private Properties
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Initialization
    override init(pageSize: Int = AppConfig.Pagination.defaultPageSize) {
        super.init(pageSize: pageSize)
        setupSearchObserver()
    }
    
    // MARK: - Search Setup
    private func setupSearchObserver() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.handleSearchTextChange(searchText)
            }
            .store(in: &cancellables)
    }
    
    private func handleSearchTextChange(_ searchText: String) {
        // Cancel previous search
        searchTask?.cancel()
        
        searchTask = Task { [weak self] in
            await self?.performSearch(searchText)
        }
    }
    
    // MARK: - Abstract Methods
    func performSearch(_ query: String) async {
        fatalError("performSearch(_:) must be overridden in subclass")
    }
    
    // MARK: - Public Methods
    func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Lifecycle
    deinit {
        searchTask?.cancel()
    }
}

// MARK: - State Management Extensions
extension BaseViewModel {
    
    /// Execute async operation with loading state management
    func executeWithLoading<T>(
        _ operation: @escaping () async throws -> T,
        onSuccess: @escaping (T) -> Void = { _ in },
        onError: @escaping (Error) -> Void = { _ in }
    ) async {
        guard !isLoading else { return }
        
        setLoadingState(true)
        
        do {
            let result = try await operation()
            onSuccess(result)
        } catch {
            onError(error)
            showErrorMessage(error.localizedDescription)
        }
        
        setLoadingState(false)
    }
    
    /// Execute async operation with loadingMore state management
    func executeWithLoadingMore<T>(
        _ operation: @escaping () async throws -> T,
        onSuccess: @escaping (T) -> Void = { _ in },
        onError: @escaping (Error) -> Void = { _ in }
    ) async {
        guard !isLoadingMore else { return }
        
        setLoadingMoreState(true)
        
        do {
            let result = try await operation()
            onSuccess(result)
        } catch {
            onError(error)
            showErrorMessage(error.localizedDescription)
        }
        
        setLoadingMoreState(false)
    }
}
