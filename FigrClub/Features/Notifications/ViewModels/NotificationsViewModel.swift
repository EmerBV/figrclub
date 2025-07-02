//
//  NotificationsViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation
import Combine

@MainActor
final class NotificationsViewModel: PaginatedViewModel<AppNotification> {
    
    // MARK: - Published Properties
    @Published var unreadCount = 0
    
    // MARK: - Use Cases
    private let loadNotificationsUseCase: LoadNotificationsUseCase
    private let markNotificationAsReadUseCase: MarkNotificationAsReadUseCase
    
    // MARK: - Initialization
    nonisolated init(
        loadNotificationsUseCase: LoadNotificationsUseCase,
        markNotificationAsReadUseCase: MarkNotificationAsReadUseCase
    ) {
        self.loadNotificationsUseCase = loadNotificationsUseCase
        self.markNotificationAsReadUseCase = markNotificationAsReadUseCase
        super.init()
    }
    
    // MARK: - Override Abstract Methods
    override func loadFirstPage() async {
        await executeWithLoading {
            try await self.loadNotificationsUseCase.execute(LoadNotificationsInput(page: 0, size: self.pageSize))
        } onSuccess: { response in
            self.replaceItems(response.content, from: response)
            self.updateUnreadCount()
            Logger.shared.info("Notifications loaded: \(response.content.count) notifications", category: "notifications")
        }
    }
    
    override func loadNextPage() async {
        await executeWithLoadingMore {
            try await self.loadNotificationsUseCase.execute(LoadNotificationsInput(page: self.currentPage + 1, size: self.pageSize))
        } onSuccess: { response in
            self.appendItems(response.content, from: response)
            Logger.shared.info("More notifications loaded: \(response.content.count) notifications", category: "notifications")
        }
    }
    
    // MARK: - Public Methods
    func markAsRead(_ notification: AppNotification) {
        guard !notification.isRead else { return }
        
        Task {
            do {
                let updatedNotification = try await markNotificationAsReadUseCase.execute(notification.id)
                updateNotification(updatedNotification)
                updateUnreadCount()
            } catch {
                showErrorMessage("Error al marcar como leída: \(error.localizedDescription)")
            }
        }
    }
    
    func markAllAsRead() {
        // TODO: Implement mark all as read use case
        let unreadNotifications = items.filter { !$0.isRead }
        
        for notification in unreadNotifications {
            markAsRead(notification)
        }
    }
    
    // MARK: - Private Methods
    private func updateNotification(_ updatedNotification: AppNotification) {
        guard let index = items.firstIndex(where: { $0.id == updatedNotification.id }) else { return }
        items[index] = updatedNotification
    }
    
    private func updateUnreadCount() {
        unreadCount = items.filter { !$0.isRead }.count
    }
}
