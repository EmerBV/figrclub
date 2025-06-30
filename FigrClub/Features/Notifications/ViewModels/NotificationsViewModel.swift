//
//  NotificationsViewModel.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation
import Combine

@MainActor
final class NotificationsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var unreadCount = 0
    
    // MARK: - Private Properties
    private let apiService: APIServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }
    
    // MARK: - Public Methods
    
    func loadNotifications() async {
        guard !isLoading else { return }
        
        isLoading = true
        
        do {
            let response: PaginatedResponse<AppNotification> = try await apiService
                .request(endpoint: .getNotifications(page: 0, size: 50), body: nil)
                .async()
            
            notifications = response.content
            updateUnreadCount()
            
        } catch {
            showErrorMessage("Error al cargar notificaciones: \(error.localizedDescription)")
            Logger.shared.error("Failed to load notifications", error: error, category: "notifications")
        }
        
        isLoading = false
    }
    
    func refreshNotifications() async {
        await loadNotifications()
    }
    
    func markAsRead(_ notification: AppNotification) {
        guard !notification.isRead else { return }
        
        Task {
            do {
                let _: AppNotification = try await apiService
                    .request(endpoint: .markNotificationAsRead(notification.id), body: nil)
                    .async()
                
                // Update local state
                if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                    notifications[index] = AppNotification(
                        id: notification.id,
                        title: notification.title,
                        message: notification.message,
                        type: notification.type,
                        entityType: notification.entityType,
                        entityId: notification.entityId,
                        isRead: true,
                        createdAt: notification.createdAt
                    )
                }
                
                updateUnreadCount()
                
            } catch {
                Logger.shared.error("Failed to mark notification as read", error: error, category: "notifications")
            }
        }
    }
    
    func markAllAsRead() {
        Task {
            do {
                try await apiService
                    .request(endpoint: .markAllNotificationsAsRead, body: nil)
                    .async()
                
                // Update local state
                notifications = notifications.map { notification in
                    AppNotification(
                        id: notification.id,
                        title: notification.title,
                        message: notification.message,
                        type: notification.type,
                        entityType: notification.entityType,
                        entityId: notification.entityId,
                        isRead: true,
                        createdAt: notification.createdAt
                    )
                }
                
                updateUnreadCount()
                
            } catch {
                showErrorMessage("Error al marcar como leídas: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteNotifications(at indexSet: IndexSet) {
        let notificationsToDelete = indexSet.map { notifications[$0] }
        
        Task {
            for notification in notificationsToDelete {
                do {
                    try await apiService
                        .request(endpoint: .deleteNotification(notification.id), body: nil)
                        .async()
                    
                    notifications.removeAll { $0.id == notification.id }
                    
                } catch {
                    Logger.shared.error("Failed to delete notification", error: error, category: "notifications")
                }
            }
            
            updateUnreadCount()
        }
    }
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
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
