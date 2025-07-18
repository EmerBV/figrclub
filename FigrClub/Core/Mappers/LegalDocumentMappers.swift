//
//  LegalDocumentMappers.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

// MARK: - Legal Document Mappers
struct LegalDocumentMappers {
    
    static func toLegalDocumentResponse(from dto: LegalDocumentResponseDTO) -> LegalDocumentResponse {
        return GenericResponseMapper.mapResponse(from: dto) { legalDocumentDataDTO in
            LegalDocumentData(
                id: legalDocumentDataDTO.id,
                documentType: EnumMapper.mapToEnum(rawValue: legalDocumentDataDTO.documentType, defaultValue: .termsOfService),
                title: legalDocumentDataDTO.title,
                slug: legalDocumentDataDTO.slug,
                content: legalDocumentDataDTO.content,
                summary: legalDocumentDataDTO.summary,
                version: legalDocumentDataDTO.version,
                effectiveDate: legalDocumentDataDTO.effectiveDate,
                publishedAt: legalDocumentDataDTO.publishedAt,
                language: legalDocumentDataDTO.language,
                country: legalDocumentDataDTO.country,
                requiresAcceptance: legalDocumentDataDTO.requiresAcceptance,
                displayOrder: legalDocumentDataDTO.displayOrder,
                documentUrl: legalDocumentDataDTO.documentUrl
            )
        }
    }
    
    static func toLegalDocumentRequestDTO(from request: LegalDocumentRequest) -> LegalDocumentRequestDTO {
        return LegalDocumentRequestDTO(
            documentType: request.documentType.rawValue,
            countryCode: request.countryCode
        )
    }
}

extension LegalDocumentMappers {
    
    static func toDomainModel(from dto: LegalDocumentResponseDTO) -> LegalDocumentResponse {
        return toLegalDocumentResponse(from: dto)
    }
    
    static func toDTO(from domainModel: LegalDocumentResponse) -> LegalDocumentResponseDTO {
        fatalError("Not implemented - reverse mapping not needed for legal documents")
    }
}
