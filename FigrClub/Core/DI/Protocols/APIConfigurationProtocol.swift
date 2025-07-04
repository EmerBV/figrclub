//
//  APIConfigurationProtocol.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation

protocol APIConfigurationProtocol {
    var baseURL: URL { get }
    var timeout: TimeInterval { get }
    var allowsConstrainedNetworkAccess: Bool { get }
}

final class APIConfiguration: APIConfigurationProtocol {
    var baseURL: URL {
        return URL(string: "https://api.figrclub.com/v1")! // Ajusta tu URL base
    }
    
    var timeout: TimeInterval {
        return 30.0
    }
    
    var allowsConstrainedNetworkAccess: Bool {
        return true
    }
}
