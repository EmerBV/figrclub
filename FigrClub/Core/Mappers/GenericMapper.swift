//
//  GenericMapper.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation

// MARK: - Generic Mapper Protocol
protocol Mappable {
    associatedtype DTO: BaseDTO
    associatedtype DomainModel
    
    static func toDomainModel(from dto: DTO) -> DomainModel
    static func toDTO(from domainModel: DomainModel) -> DTO
}

// MARK: - Generic Response Mapper
final class GenericResponseMapper {
    
    /// Mapear response genérico con datos simples
    static func mapResponse<DTOData, DomainData>(
        from dto: ApiResponseDTO<DTOData>,
        dataMapper: (DTOData) -> DomainData
    ) -> ApiResponse<DomainData> {
        return ApiResponse(
            message: dto.message,
            data: dataMapper(dto.data),
            timestamp: Date(timeIntervalSince1970: dto.timestamp / 1000.0),
            currency: dto.currency,
            locale: dto.locale,
            status: dto.status
        )
    }
    
    /// Mapear response de lista paginada
    static func mapPaginatedResponse<DTOItem, DomainItem>(
        from dto: ApiResponseDTO<PaginatedDataDTO<DTOItem>>,
        itemMapper: (DTOItem) -> DomainItem
    ) -> ApiResponse<PaginatedData<DomainItem>> {
        return mapResponse(from: dto) { paginatedDTO in
            PaginatedData(
                content: paginatedDTO.content.map(itemMapper),
                totalElements: paginatedDTO.totalElements,
                totalPages: paginatedDTO.totalPages,
                currentPage: paginatedDTO.currentPage,
                size: paginatedDTO.size
            )
        }
    }
}

// MARK: - Date Mapper Utility
final class DateMapper {
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static let simpleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    static func dateFromString(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        // Try ISO8601 with milliseconds first
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Try simple format
        if let date = simpleDateFormatter.date(from: dateString) {
            return date
        }
        
        // Fallback
        return ISO8601DateFormatter().date(from: dateString)
    }
    
    static func stringFromDate(_ date: Date) -> String {
        return iso8601Formatter.string(from: date)
    }
    
    static func dateFromTimestamp(_ timestamp: Double) -> Date {
        return Date(timeIntervalSince1970: timestamp / 1000.0)
    }
    
    static func timestampFromDate(_ date: Date) -> Double {
        return date.timeIntervalSince1970 * 1000.0
    }
}

// MARK: - Paginated Data Models
struct PaginatedDataDTO<T: Codable>: BaseDTO {
    let content: [T]
    let totalElements: Int
    let totalPages: Int
    let currentPage: Int
    let size: Int
    
    enum CodingKeys: String, CodingKey {
        case content
        case totalElements = "total_elements"
        case totalPages = "total_pages"
        case currentPage = "current_page"
        case size
    }
}

struct PaginatedData<T> {
    let content: [T]
    let totalElements: Int
    let totalPages: Int
    let currentPage: Int
    let size: Int
}

// MARK: - Enum Mapper Utility
final class EnumMapper {
    static func mapToEnum<T: RawRepresentable>(
        rawValue: T.RawValue,
        defaultValue: T
    ) -> T where T.RawValue: Equatable {
        return T(rawValue: rawValue) ?? defaultValue
    }
}

// MARK: - Collection Extensions
extension Array {
    func mapToDomain<DomainType>(using mapper: (Element) -> DomainType) -> [DomainType] {
        return self.map(mapper)
    }
}

extension Optional {
    func mapToDomain<DomainType>(using mapper: (Wrapped) -> DomainType) -> DomainType? {
        return self.map(mapper)
    }
} 