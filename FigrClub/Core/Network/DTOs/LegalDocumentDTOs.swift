//
//  LegalDocumentDTOs.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

// MARK: - Legal Document DTOs
struct LegalDocumentRequestDTO: BaseDTO {
    let documentType: String
    let countryCode: String
}

struct LegalDocumentDataDTO: BaseDTO {
    let id: Int
    let documentType: String
    let title: String
    let slug: String
    let content: String
    let summary: String
    let version: String
    let effectiveDate: String
    let publishedAt: String
    let language: String
    let country: String
    let requiresAcceptance: Bool
    let displayOrder: Int
    let documentUrl: String
}

typealias LegalDocumentResponseDTO = ApiResponseDTO<LegalDocumentDataDTO>
