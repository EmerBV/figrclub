//
//  NotificationMappers.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

// MARK: - Notification Mappers
struct NotificationMappers {
    
    static func toNotificationResponse(from dto: NotificationResponseDTO) -> NotificationResponse {
        return GenericResponseMapper.mapResponse(from: dto, dataMapper: mapNotification)
    }
    
    static func toNotificationListResponse(from dto: NotificationListResponseDTO) -> NotificationListResponse {
        return GenericResponseMapper.mapResponse(from: dto) { listData in
            PaginatedData<NotificationData>(
                content: listData.content.map(mapNotification),
                totalElements: listData.totalElements,
                totalPages: listData.totalPages,
                currentPage: listData.currentPage,
                size: listData.size
            )
        }
    }
    
    private static func mapNotification(_ dto: NotificationDataDTO) -> NotificationData {
        return NotificationData(
            id: dto.id,
            userId: dto.userId,
            title: dto.title,
            message: dto.message,
            type: EnumMapper.mapToEnum(rawValue: dto.type, defaultValue: NotificationType.system),
            isRead: dto.isRead,
            createdAt: DateMapper.dateFromString(dto.createdAt) ?? Date(),
            actionUrl: dto.actionUrl,
            metadata: dto.metadata
        )
    }
}
