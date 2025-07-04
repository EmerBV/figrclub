//
//  NotificationProfileComponents.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 30/6/25.
//

import Foundation
import SwiftUI

// MARK: - Notification Row View
struct NotificationRowView: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Icon
            Image(systemName: notification.type.iconName)
                .font(.figrBody)
                .foregroundColor(notification.type.color)
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(notification.title)
                    .font(.figrCallout.weight(.medium))
                    .foregroundColor(.figrTextPrimary)
                
                Text(notification.message)
                    .font(.figrFootnote)
                    .foregroundColor(.figrTextSecondary)
                    .lineLimit(2)
                
                Text(formatCreatedAt(notification.createdAt))
                    .font(.figrCaption)
                    .foregroundColor(.figrTextSecondary)
            }
            
            Spacer()
            
            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(Color.figrPrimary)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, Spacing.xSmall)
        .background(notification.isRead ? .clear : .figrPrimary.opacity(0.05))
    }
    
    private func formatCreatedAt(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return "hace un momento"
        }
        return date.timeAgoDisplay
    }
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    let user: User?
    
    var body: some View {
        VStack(spacing: Spacing.large) {
            // Avatar and basic info
            VStack(spacing: Spacing.medium) {
                FigrAvatar(
                    imageURL: user?.profileImageUrl,
                    size: 100,
                    fallbackText: user?.firstName.firstLetterCapitalized ?? "?"
                )
                
                VStack(spacing: Spacing.xSmall) {
                    Text(user?.fullName ?? "Usuario")
                        .font(.figrTitle2)
                        .foregroundColor(.figrTextPrimary)
                    
                    Text("@\(user?.username ?? "username")")
                        .font(.figrCallout)
                        .foregroundColor(.figrTextSecondary)
                    
                    if let bio = user?.bio {
                        Text(bio)
                            .font(.figrBody)
                            .foregroundColor(.figrTextPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                // User type badge
                if let userType = user?.userType {
                    FigrBadge(text: userType.displayName, style: .primary)
                }
            }
        }
    }
}

// MARK: - Profile Stats View
struct ProfileStatsView: View {
    let stats: UserStats?
    
    var body: some View {
        HStack {
            StatItem(title: "Posts", value: stats?.postsCount ?? 0)
            Spacer()
            StatItem(title: "Seguidores", value: stats?.followersCount ?? 0)
            Spacer()
            StatItem(title: "Siguiendo", value: stats?.followingCount ?? 0)
            Spacer()
            StatItem(title: "Likes", value: stats?.likesCount ?? 0)
        }
        .padding(.horizontal, Spacing.xLarge)
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: Int
    
    var body: some View {
        VStack(spacing: Spacing.xSmall) {
            Text("\(value)")
                .font(.figrTitle3)
                .foregroundColor(.figrTextPrimary)
            
            Text(title)
                .font(.figrCaption)
                .foregroundColor(.figrTextSecondary)
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.figrPrimary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.figrTextPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.figrCaption)
                            .foregroundColor(.figrTextSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.figrTextSecondary)
                    .font(.figrCaption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Extensions for Notification Types
extension NotificationType {
    var iconName: String {
        switch self {
        case .like: return "heart.fill"
        case .comment: return "bubble.left.fill"
        case .follow: return "person.badge.plus"
        case .newPost: return "doc.text.fill"
        case .marketplaceSale: return "cart.fill"
        case .marketplaceQuestion: return "questionmark.circle.fill"
        case .system: return "gear.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .like: return .figrError
        case .comment: return .figrPrimary
        case .follow: return .figrSuccess
        case .newPost: return .figrAccent
        case .marketplaceSale: return .figrWarning
        case .marketplaceQuestion: return .figrSecondary
        case .system: return .figrTextSecondary
        }
    }
}

