//
//  APIError.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation

struct APIError: Error, Codable {
    let message: String
    let code: String?
    let timestamp: String
    
    var localizedDescription: String {
        return message
    }
}
