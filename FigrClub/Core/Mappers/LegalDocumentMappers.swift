//
//  LegalDocumentMappers.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

// MARK: - Legal Document Mappers (Deprecated - Use DTOMapper.swift)
// Este archivo se mantiene para retrocompatibilidad
// Las nuevas implementaciones deberían usar LegalDocumentMappers en DTOMapper.swift

extension LegalDocumentMappers {
    
    static func toDomainModel(from dto: LegalDocumentResponseDTO) -> LegalDocumentResponse {
        return toLegalDocumentResponse(from: dto)
    }
    
    static func toDTO(from domainModel: LegalDocumentResponse) -> LegalDocumentResponseDTO {
        fatalError("Not implemented - reverse mapping not needed for legal documents")
    }
}
