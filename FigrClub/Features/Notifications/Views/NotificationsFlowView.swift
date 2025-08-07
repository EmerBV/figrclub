//
//  NotificationsFlowView.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 14/7/25.
//

import SwiftUI
import Kingfisher

struct NotificationsFlowView: View {
    let user: User
    
    @Environment(\.localizationManager) private var localizationManager
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    // MARK: - State Properties
    @State private var selectedSegment: NotificationSegment = .messages
    @State private var notifications: [AppNotification] = sampleNotifications
    @State private var isLoading = false
    @State private var showingNotificationDetail = false
    @State private var selectedNotificationId: String?
    
    var body: some View {
        FigrNavigationStack {
            VStack(spacing: 0) {
                segmentedControl
                contentSection
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingNotificationDetail) {
            if let notificationId = selectedNotificationId {
                NotificationDetailSheet(
                    notificationId: notificationId,
                    user: user
                )
            }
        }
        .onAppear {
            loadNotifications()
        }
    }
    
    // MARK: - Segmented Control
    private var segmentedControl: some View {
        HStack(spacing: 0) {
            segmentButton(
                title: localizationManager.localizedString(for: .messagesString),
                segment: .messages,
                isSelected: selectedSegment == .messages
            )
            
            segmentButton(
                title: localizationManager.localizedString(for: .notificationsString),
                segment: .notifications,
                isSelected: selectedSegment == .notifications,
                badgeCount: unreadNotificationsCount
            )
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(themeManager.currentBackgroundColor)
        )
        .padding(.horizontal, AppTheme.Padding.large)
        .padding(.top, AppTheme.Padding.large)
        .padding(.bottom, AppTheme.Padding.small)
        //.background(Color.figrRedAccent)
    }
    
    private func segmentButton(
        title: String,
        segment: NotificationSegment,
        isSelected: Bool,
        badgeCount: Int = 0
    ) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSegment = segment
            }
        } label: {
            HStack {
                Spacer()
                
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(
                            isSelected ? .white : .figrTextTertiary
                        )
                    
                    if badgeCount > 0 {
                        Circle()
                            .fill(Color.figrRedAccent)
                            .frame(width: AppTheme.LayoutConstants.badgeSize, height: AppTheme.LayoutConstants.badgeSize)
                            .overlay(
                                Text("\(badgeCount)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                Spacer()
            }
            .frame(height: AppTheme.LayoutConstants.segmentControlHeight)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium - 2)
                    .fill(isSelected ? Color.black : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        Group {
            switch selectedSegment {
            case .messages:
                messagesListView
            case .notifications:
                notificationsListView
            }
        }
    }
    
    // MARK: - Messages List View
    private var messagesListView: some View {
        FigrRefreshableScrollView(refreshAction: refreshNotifications) {
            LazyVStack(spacing: 0) {
                ForEach(filteredMessages) { message in
                    MessageRowView(
                        message: message,
                        currentUser: user
                    )
                    .onTapGesture {
                        handleMessageTap(message)
                    }
                }
            }
        }
    }
    
    // MARK: - Notifications List View
    private var notificationsListView: some View {
        FigrRefreshableScrollView(refreshAction: refreshNotifications) {
            LazyVStack(spacing: 0) {
                ForEach(filteredNotifications) { notification in
                    NotificationRowView(
                        notification: notification,
                        currentUser: user
                    )
                    .onTapGesture {
                        handleNotificationTap(notification)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredMessages: [MessageNotification] {
        notifications.compactMap { notification in
            if case .message(let message) = notification.type {
                return message
            }
            return nil
        }
        .sorted { $0.createdAt > $1.createdAt }
    }
    
    private var filteredNotifications: [SystemNotification] {
        notifications.compactMap { notification in
            if case .system(let systemNotification) = notification.type {
                return systemNotification
            }
            return nil
        }
        .sorted { $0.createdAt > $1.createdAt }
    }
    
    private var unreadNotificationsCount: Int {
        filteredNotifications.filter { !$0.isRead }.count
    }
    
    // MARK: - Actions
    private func handleMessageTap(_ message: MessageNotification) {
        // TODO: Navigate to conversation
        //navigationCoordinator.navigateToConversation(with: message.senderId)
    }
    
    private func handleNotificationTap(_ notification: SystemNotification) {
        selectedNotificationId = notification.id
        showingNotificationDetail = true
        
        // Mark as read if unread
        if !notification.isRead {
            markNotificationAsRead(notification.id)
        }
    }
    
    private func loadNotifications() {
        isLoading = true
        
        Task {
            // TODO: Load from API
            try? await Task.sleep(nanoseconds: 500_000_000) // Simulate loading
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func refreshNotifications() async {
        // TODO: Refresh from API
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    private func markNotificationAsRead(_ notificationId: String) {
        // TODO: Mark as read in API
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            var updatedNotification = notifications[index]
            if case .system(var systemNotification) = updatedNotification.type {
                systemNotification.isRead = true
                updatedNotification.type = .system(systemNotification)
                notifications[index] = updatedNotification
            }
        }
    }
}

// MARK: - Notification Segment Enum
enum NotificationSegment: CaseIterable {
    case messages
    case notifications
    
    var title: String {
        switch self {
        case .messages:
            return "Mensajes"
        case .notifications:
            return "Notificaciones"
        }
    }
}

// MARK: - Message Row View
struct MessageRowView: View {
    let message: MessageNotification
    let currentUser: User
    
    @Environment(\.localizationManager) private var localizationManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Avatar
            KFImage(URL(string: message.senderAvatarUrl))
                .placeholder {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 56, height: 56)
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.senderName)
                        .font(.system(size: 16, weight: .semibold))
                        .themedTextColor(.primary)
                    
                    Spacer()
                    
                    Text(formatDate(message.createdAt))
                        .font(.system(size: 14))
                        .themedTextColor(.secondary)
                }
                
                Text(message.lastMessage)
                    .font(.system(size: 15))
                    .foregroundColor(message.isRead ? .secondary : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if !message.isRead {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.figrBlueAccent)
                            .font(.system(size: 12))
                        
                        Text(localizationManager.localizedString(for: .unreadString))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.figrBlueAccent)
                        
                        Spacer()
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, AppTheme.Padding.large)
        .padding(.vertical, AppTheme.Padding.medium)
        .background(Color.clear)
        
        Divider()
            .background(themeManager.currentBorderColor)
            .padding(.horizontal, AppTheme.Padding.large)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Notification Row View
struct NotificationRowView: View {
    let notification: SystemNotification
    let currentUser: User
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Avatar or Icon
            KFImage(URL(string: notification.imageUrl ?? ""))
                .placeholder {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 56, height: 56)
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: notification.type.iconName)
                            .foregroundColor(notification.type.color)
                            .font(.system(size: 14))
                        
                        Text(notification.title)
                            .font(.system(size: 16, weight: .medium))
                            .themedTextColor(.primary)
                    }
                    
                    Spacer()
                    
                    Text(formatTimeAgo(notification.createdAt))
                        .font(.system(size: 14))
                        .themedTextColor(.secondary)
                }
                
                Text(notification.message)
                    .font(.system(size: 15))
                    .themedTextColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.horizontal, AppTheme.Padding.large)
        .padding(.vertical, AppTheme.Padding.medium)
        .background(
            notification.isRead ? Color.clear : Color.blue.opacity(0.05)
        )
        
        Divider()
            .background(themeManager.currentBorderColor)
            .padding(.horizontal, AppTheme.Padding.large)
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Sample Data Models
struct AppNotification: Identifiable {
    let id: String
    var type: NotificationType
    let createdAt: Date
    
    enum NotificationType {
        case message(MessageNotification)
        case system(SystemNotification)
    }
}

struct MessageNotification: Identifiable {
    let id: String
    let senderId: String
    let senderName: String
    let senderAvatarUrl: String
    let lastMessage: String
    let isRead: Bool
    let createdAt: Date
}

struct SystemNotification: Identifiable {
    let id: String
    let title: String
    let message: String
    let type: SystemNotificationType
    let imageUrl: String?
    var isRead: Bool
    let createdAt: Date
    
    enum SystemNotificationType {
        case favorite
        case comment
        case follow
        case sale
        case system
        
        var iconName: String {
            switch self {
            case .favorite:
                return "star.fill"
            case .comment:
                return "message.fill"
            case .follow:
                return "person.badge.plus"
            case .sale:
                return "cart.fill"
            case .system:
                return "bell.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .favorite:
                return .yellow
            case .comment:
                return .blue
            case .follow:
                return .green
            case .sale:
                return .orange
            case .system:
                return .gray
            }
        }
    }
}

// MARK: - Sample Data
let sampleNotifications: [AppNotification] = [
    AppNotification(
        id: "1",
        type: .message(MessageNotification(
            id: "msg1",
            senderId: "user1",
            senderName: "Jujutsu Kaisen Dream Boat x Time S...",
            senderAvatarUrl: "https://example.com/avatar1.jpg",
            lastMessage: "Vale gracias",
            isRead: false,
            createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        )),
        createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
    ),
    AppNotification(
        id: "2",
        type: .message(MessageNotification(
            id: "msg2",
            senderId: "user2",
            senderName: "Alex",
            senderAvatarUrl: "https://example.com/avatar2.jpg",
            lastMessage: "Perfecto, ¡muchas gracias!",
            isRead: true,
            createdAt: Calendar.current.date(byAdding: .day, value: -24, to: Date()) ?? Date()
        )),
        createdAt: Calendar.current.date(byAdding: .day, value: -24, to: Date()) ?? Date()
    ),
    AppNotification(
        id: "3",
        type: .system(SystemNotification(
            id: "notif1",
            title: "Tienes un nuevo favorito",
            message: "¡\"Jujutsu Kaisen Dream Boat x Time Studio Satoru Gojo Resin Statue\" está gustando!",
            type: .favorite,
            imageUrl: "https://example.com/product1.jpg",
            isRead: false,
            createdAt: Calendar.current.date(byAdding: .hour, value: -9, to: Date()) ?? Date()
        )),
        createdAt: Calendar.current.date(byAdding: .hour, value: -9, to: Date()) ?? Date()
    ),
    AppNotification(
        id: "4",
        type: .message(MessageNotification(
            id: "msg3",
            senderId: "user3",
            senderName: "fausto",
            senderAvatarUrl: "https://example.com/avatar3.jpg",
            lastMessage: "Lo vendo junto",
            isRead: true,
            createdAt: Calendar.current.date(byAdding: .day, value: -28, to: Date()) ?? Date()
        )),
        createdAt: Calendar.current.date(byAdding: .day, value: -28, to: Date()) ?? Date()
    )
]

// MARK: - Notification Detail Sheet
struct NotificationDetailSheet: View {
    let notificationId: String
    let user: User
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        FigrNavigationStack {
            VStack {
                Text("Detalle de notificación")
                    .font(.title2)
                    .padding()
                
                Text("ID: \(notificationId)")
                    .font(.caption)
                    .themedTextColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Notificación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}
