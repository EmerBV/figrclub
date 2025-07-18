//
//  LocationMappers.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 18/7/25.
//

import Foundation

// MARK: - Location Mappers
struct LocationMappers {
    
    static func toLocationResponse(from dto: LocationResponseDTO) -> LocationResponse {
        return GenericResponseMapper.mapResponse(from: dto) { locationDataDTO in
            LocationData(
                latitude: locationDataDTO.latitude,
                longitude: locationDataDTO.longitude,
                country: locationDataDTO.country,
                city: locationDataDTO.city,
                state: locationDataDTO.state,
                address: locationDataDTO.address,
                postalCode: locationDataDTO.postalCode,
                timezone: locationDataDTO.timezone,
                source: locationDataDTO.source,
                accuracy: EnumMapper.mapToEnum(rawValue: locationDataDTO.accuracy, defaultValue: LocationAccuracy.unknown),
                detected: locationDataDTO.detected
            )
        }
    }
}
