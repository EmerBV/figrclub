//
//  LegalDocumentMappers.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

// MARK: - Legal Document Mappers
struct LegalDocumentMappers: Mappable {
    typealias DTO = LegalDocumentResponseDTO
    typealias DomainModel = LegalDocumentResponse
    
    static func toDomainModel(from dto: LegalDocumentResponseDTO) -> LegalDocumentResponse {
        return GenericResponseMapper.mapResponse(from: dto, dataMapper: mapLegalDocument)
    }
    
    static func toDTO(from domainModel: LegalDocumentResponse) -> LegalDocumentResponseDTO {
        fatalError("Not implemented - reverse mapping not needed for legal documents")
    }
    
    // MARK: - Private Mapping Methods
    
    private static func mapLegalDocument(_ dto: LegalDocumentDataDTO) -> LegalDocument {
        return LegalDocument(
            id: dto.id,
            documentType: EnumMapper.mapToEnum(rawValue: dto.documentType, defaultValue: .termsOfService),
            title: dto.title,
            slug: dto.slug,
            content: dto.content,
            summary: dto.summary,
            version: dto.version,
            effectiveDate: dto.effectiveDate,
            publishedAt: dto.publishedAt,
            language: dto.language,
            country: dto.country,
            requiresAcceptance: dto.requiresAcceptance,
            displayOrder: dto.displayOrder,
            documentUrl: dto.documentUrl
        )
    }
}
