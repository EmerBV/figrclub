//
//  ProfileSearchView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 12/8/25.
//

import SwiftUI
import Kingfisher

struct ProfileSearchView: View {
    @Environment(\.localizationManager) private var localizationManager
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @State private var recentSearches: [String] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Error>?
    
    @Environment(\.dismiss) private var dismiss
    
    let currentUser: User
    
    var body: some View {
        FigrNavigationStack {
            VStack(spacing: 0) {
                searchSection
                
                if searchText.isEmpty {
                    defaultContent
                } else if isSearching {
                    loadingContent
                } else {
                    searchResultsContent
                }
                
                Spacer()
            }
            .navigationTitle(localizationManager.localizedString(for: .search))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(for: .close)) {
                        dismiss()
                    }
                    .themedTextColor(.primary)
                }
            }
        }
        .onAppear {
            loadRecentSearches()
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .themedTextColor(.secondary)
            
            TextField(localizationManager.localizedString(for: .searchProfilesPlaceholder), text: $searchText)
                .themedTextColor(.primary)
                .themedFont(.bodyMedium)
                .submitLabel(.search)
                .onSubmit {
                    performSearch()
                }
                .onChange(of: searchText) { oldValue, newValue in
                    // Debounce search
                    searchTask?.cancel()
                    if !newValue.isEmpty {
                        searchTask = Task {
                            try await Task.sleep(for: .milliseconds(300))
                            await performSearchDebounced(query: newValue)
                        }
                    } else {
                        searchResults = []
                        isSearching = false
                    }
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                    isSearching = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .themedTextColor(.secondary)
                }
            }
        }
        .padding(AppTheme.Padding.medium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.input)
                .fill(themeManager.currentCardColor)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.input)
                        .stroke(Color.figrBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, AppTheme.Padding.large)
        .padding(.bottom, AppTheme.Padding.medium)
    }
    
    // MARK: - Default Content
    private var defaultContent: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            if !recentSearches.isEmpty {
                recentSearchesSection
            }
            
            suggestedUsersSection
        }
        .padding(.horizontal, AppTheme.Padding.large)
    }
    
    // MARK: - Recent Searches Section
    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(localizationManager.localizedString(for: .recentSearches))
                    .themedFont(.titleMedium)
                    .themedTextColor(.primary)
                
                Spacer()
                
                Button {
                    clearRecentSearches()
                } label: {
                    Text(localizationManager.localizedString(for: .clearAll))
                        .themedFont(.bodySmall)
                        .themedTextColor(.secondary)
                }
            }
            
            LazyVStack(spacing: AppTheme.Spacing.small) {
                ForEach(recentSearches, id: \.self) { search in
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .themedTextColor(.secondary)
                            .font(.body)
                        
                        Text(search)
                            .themedFont(.bodyMedium)
                            .themedTextColor(.primary)
                        
                        Spacer()
                        
                        Button {
                            removeRecentSearch(search)
                        } label: {
                            Image(systemName: "xmark")
                                .themedTextColor(.tertiary)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, AppTheme.Padding.small)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        searchText = search
                        performSearch()
                    }
                }
            }
        }
    }
    
    // MARK: - Suggested Users Section
    private var suggestedUsersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(localizationManager.localizedString(for: .suggestedUsers))
                .themedFont(.titleMedium)
                .themedTextColor(.primary)
            
            LazyVStack(spacing: AppTheme.Spacing.medium) {
                ForEach(generateSuggestedUsers()) { user in
                    ProfileResultRow(
                        user: user,
                        currentUser: currentUser,
                        onTap: {
                            navigationCoordinator.showUserProfileDetail(user: user)
                            dismiss()
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Loading Content
    private var loadingContent: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            ProgressView()
                .tint(.figrPrimary)
                .scaleEffect(1.2)
            
            Text(localizationManager.localizedString(for: .searchingProfiles))
                .themedFont(.bodyMedium)
                .themedTextColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, AppTheme.Padding.xxxLarge)
    }
    
    // MARK: - Search Results Content
    private var searchResultsContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            if searchResults.isEmpty {
                emptyResultsView
            } else {
                HStack {
                    Text(localizationManager.localizedString(for: .searchResults))
                        .themedFont(.titleMedium)
                        .themedTextColor(.primary)
                    
                    Spacer()
                    
                    Text("\(searchResults.count) \(localizationManager.localizedString(for: .resultsFound))")
                        .themedFont(.bodySmall)
                        .themedTextColor(.secondary)
                }
                .padding(.horizontal, AppTheme.Padding.large)
                
                FigrScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.medium) {
                        ForEach(searchResults) { result in
                            ProfileResultRow(
                                user: result.user,
                                currentUser: currentUser,
                                highlightedText: searchText,
                                onTap: {
                                    addToRecentSearches(searchText)
                                    navigationCoordinator.showUserProfileDetail(user: result.user)
                                    dismiss()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AppTheme.Padding.large)
                }
            }
        }
    }
    
    // MARK: - Empty Results View
    private var emptyResultsView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 48))
                .themedTextColor(.tertiary)
            
            VStack(spacing: AppTheme.Spacing.small) {
                Text(localizationManager.localizedString(for: .noProfilesFound))
                    .themedFont(.titleMedium)
                    .themedTextColor(.primary)
                
                Text(localizationManager.localizedString(for: .tryDifferentSearch))
                    .themedFont(.bodyMedium)
                    .themedTextColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, AppTheme.Padding.xxxLarge)
        .padding(.horizontal, AppTheme.Padding.large)
    }
    
    // MARK: - Private Methods
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSearching = true
        searchTask?.cancel()
        
        searchTask = Task {
            try await Task.sleep(for: .milliseconds(500)) // Simular delay de red
            
            await MainActor.run {
                let results = mockSearchResults(for: searchText)
                self.searchResults = results
                self.isSearching = false
                
                if !results.isEmpty {
                    addToRecentSearches(searchText)
                }
            }
        }
    }
    
    @MainActor
    private func performSearchDebounced(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSearching = true
        
        do {
            try await Task.sleep(for: .milliseconds(500))
            let results = mockSearchResults(for: query)
            self.searchResults = results
            self.isSearching = false
        } catch {
            // Task was cancelled
            return
        }
    }
    
    private func loadRecentSearches() {
        // En una implementación real, cargar desde UserDefaults o Core Data
        recentSearches = UserDefaults.standard.stringArray(forKey: "recent_profile_searches") ?? []
    }
    
    private func addToRecentSearches(_ search: String) {
        let trimmedSearch = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return }
        
        // Remover si ya existe
        recentSearches.removeAll { $0 == trimmedSearch }
        
        // Agregar al inicio
        recentSearches.insert(trimmedSearch, at: 0)
        
        // Mantener solo los últimos 10
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
        
        // Guardar en UserDefaults
        UserDefaults.standard.set(recentSearches, forKey: "recent_profile_searches")
    }
    
    private func removeRecentSearch(_ search: String) {
        recentSearches.removeAll { $0 == search }
        UserDefaults.standard.set(recentSearches, forKey: "recent_profile_searches")
    }
    
    private func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "recent_profile_searches")
    }
    
    private func generateSuggestedUsers() -> [User] {
        // En una implementación real, esto vendría de la API
        return sampleSuggestedUsers.prefix(5).map { $0 }
    }
}

// MARK: - Profile Result Row
struct ProfileResultRow: View {
    let user: User
    let currentUser: User
    let highlightedText: String?
    let onTap: () -> Void
    
    @Environment(\.localizationManager) private var localizationManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    init(user: User, currentUser: User, highlightedText: String? = nil, onTap: @escaping () -> Void) {
        self.user = user
        self.currentUser = currentUser
        self.highlightedText = highlightedText
        self.onTap = onTap
    }
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Profile Image
            KFImage(URL(string: mockProfileImageURL(for: user)))
                .profileImageStyle(size: 48)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                // Display Name
                HStack {
                    highlightedDisplayName
                    
                    // Verification Badge
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.body)
                            .foregroundColor(.figrBlueAccent)
                    }
                }
                
                // Username
                Text("\(user.username)")
                    .themedFont(.bodyXSmall)
                    .themedTextColor(.secondary)
                
                /*
                 HStack(spacing: AppTheme.Spacing.medium) {
                 HStack(spacing: AppTheme.Spacing.xSmall) {
                 Text("\(user.followersCount)")
                 .themedFont(.bodySmall)
                 .themedTextColor(.primary)
                 Text(localizationManager.localizedString(for: .followers))
                 .themedFont(.bodySmall)
                 .themedTextColor(.secondary)
                 }
                 
                 HStack(spacing: AppTheme.Spacing.xSmall) {
                 Text("\(user.postsCount)")
                 .themedFont(.bodySmall)
                 .themedTextColor(.primary)
                 Text(localizationManager.localizedString(for: .posts))
                 .themedFont(.bodySmall)
                 .themedTextColor(.secondary)
                 }
                 }
                 */
            }
            
            Spacer()
            
            // Follow Button (if not current user)
            if user.id != currentUser.id {
                Button {
                    // TODO: Implementar lógica de seguir/no seguir
                } label: {
                    Text(localizationManager.localizedString(for: .follow))
                        .themedFont(.buttonSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Padding.medium)
                        .padding(.vertical, AppTheme.Padding.small)
                        .background(Color.figrBlueAccent)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                }
            }
        }
        .padding(.vertical, AppTheme.Padding.small)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private var highlightedDisplayName: some View {
        Group {
            if let highlightedText = highlightedText, !highlightedText.isEmpty {
                Text(attributedDisplayName)
                    .themedFont(.bodyMedium)
            } else {
                Text(user.displayName)
                    .themedFont(.bodyMedium)
                    .themedTextColor(.primary)
            }
        }
    }
    
    private var attributedDisplayName: AttributedString {
        var attributedString = AttributedString(user.displayName)
        
        if let highlightedText = highlightedText?.lowercased() {
            let displayNameLowercased = user.displayName.lowercased()
            
            if let range = displayNameLowercased.range(of: highlightedText) {
                let startIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: displayNameLowercased.distance(from: displayNameLowercased.startIndex, to: range.lowerBound))
                let endIndex = attributedString.index(startIndex, offsetByCharacters: highlightedText.count)
                
                attributedString[startIndex..<endIndex].foregroundColor = .figrBlueAccent
                attributedString[startIndex..<endIndex].font = .system(.body, design: .default, weight: .semibold)
            }
        }
        
        return attributedString
    }
}

// MARK: - Search Result Model
struct SearchResult: Identifiable {
    let id = UUID()
    let user: User
    let matchType: MatchType
    
    enum MatchType {
        case displayName
        case username
        case fullName
    }
}

// MARK: - Mock Data and Helper Functions
private func mockSearchResults(for query: String) -> [SearchResult] {
    let lowercasedQuery = query.lowercased()
    
    return sampleUsers.compactMap { user in
        if user.displayName.lowercased().contains(lowercasedQuery) {
            return SearchResult(user: user, matchType: .displayName)
        } else if user.username.lowercased().contains(lowercasedQuery) {
            return SearchResult(user: user, matchType: .username)
        } else if user.fullName.lowercased().contains(lowercasedQuery) {
            return SearchResult(user: user, matchType: .fullName)
        }
        return nil
    }
}

private func mockProfileImageURL(for user: User) -> String {
    // En una implementación real, esto vendría del backend
    return "https://i.pravatar.cc/150?u=\(user.id)"
}

// MARK: - Sample Data
private let sampleUsers: [User] = [
    User(
        id: 1001,
        firstName: "Ana",
        lastName: "García",
        email: "ana.garcia@example.com",
        displayName: "ana_collector",
        fullName: "Ana García",
        birthDate: nil,
        city: "Madrid",
        country: "España",
        phone: nil,
        preferredLanguage: "es",
        active: true,
        enabled: true,
        accountNonExpired: true,
        accountNonLocked: true,
        credentialsNonExpired: true,
        emailVerified: true,
        emailVerifiedAt: "2024-01-01T00:00:00.000Z",
        isVerified: true,
        isPrivate: false,
        isPro: true,
        canAccessProFeatures: true,
        proSeller: false,
        isActiveSellerProfile: false,
        isSellingActive: false,
        individualUser: true,
        admin: false,
        role: "USER",
        roleDescription: "Regular user",
        roleId: 1,
        hasProfileImage: true,
        hasCoverImage: true,
        activeImageCount: 15,
        followersCount: 2543,
        followingCount: 189,
        postsCount: 127,
        purchasesCount: 8,
        createdAt: "2023-03-15T00:00:00.000Z",
        createdBy: nil,
        lastActivityAt: "2024-08-11T15:30:00.000Z",
        imageCapabilities: nil,
        maxProfileImageSizeMB: "5",
        maxCoverImageSizeMB: "10"
    ),
    User(
        id: 1002,
        firstName: "Carlos",
        lastName: "Rodríguez",
        email: "carlos.rodriguez@example.com",
        displayName: "carlosrod",
        fullName: "Carlos Rodríguez",
        birthDate: nil,
        city: "Barcelona",
        country: "España",
        phone: nil,
        preferredLanguage: "es",
        active: true,
        enabled: true,
        accountNonExpired: true,
        accountNonLocked: true,
        credentialsNonExpired: true,
        emailVerified: true,
        emailVerifiedAt: "2024-01-01T00:00:00.000Z",
        isVerified: false,
        isPrivate: false,
        isPro: false,
        canAccessProFeatures: false,
        proSeller: true,
        isActiveSellerProfile: true,
        isSellingActive: true,
        individualUser: true,
        admin: false,
        role: "USER",
        roleDescription: "Regular user",
        roleId: 1,
        hasProfileImage: true,
        hasCoverImage: false,
        activeImageCount: 8,
        followersCount: 891,
        followingCount: 234,
        postsCount: 45,
        purchasesCount: 12,
        createdAt: "2023-06-20T00:00:00.000Z",
        createdBy: nil,
        lastActivityAt: "2024-08-12T09:15:00.000Z",
        imageCapabilities: nil,
        maxProfileImageSizeMB: "5",
        maxCoverImageSizeMB: "10"
    ),
    User(
        id: 1003,
        firstName: "María",
        lastName: "López",
        email: "maria.lopez@example.com",
        displayName: "maria_anime",
        fullName: "María López",
        birthDate: nil,
        city: "Valencia",
        country: "España",
        phone: nil,
        preferredLanguage: "es",
        active: true,
        enabled: true,
        accountNonExpired: true,
        accountNonLocked: true,
        credentialsNonExpired: true,
        emailVerified: true,
        emailVerifiedAt: "2024-01-01T00:00:00.000Z",
        isVerified: true,
        isPrivate: false,
        isPro: true,
        canAccessProFeatures: true,
        proSeller: false,
        isActiveSellerProfile: false,
        isSellingActive: false,
        individualUser: true,
        admin: false,
        role: "USER",
        roleDescription: "Regular user",
        roleId: 1,
        hasProfileImage: true,
        hasCoverImage: true,
        activeImageCount: 22,
        followersCount: 4156,
        followingCount: 156,
        postsCount: 203,
        purchasesCount: 15,
        createdAt: "2023-01-10T00:00:00.000Z",
        createdBy: nil,
        lastActivityAt: "2024-08-12T11:45:00.000Z",
        imageCapabilities: nil,
        maxProfileImageSizeMB: "5",
        maxCoverImageSizeMB: "10"
    )
]

private let sampleSuggestedUsers: [User] = Array(sampleUsers.prefix(3))

