//
//  URLSessionProviderProtocol.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation

protocol URLSessionProviderProtocol {
    var session: URLSession { get }
}

final class URLSessionProvider: URLSessionProviderProtocol {
    let session: URLSession
    private let configuration: APIConfigurationProtocol
    private let logger: NetworkLoggerProtocol
    
    init(configuration: APIConfigurationProtocol, logger: NetworkLoggerProtocol) {
        self.configuration = configuration
        self.logger = logger
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = configuration.timeout
        config.allowsConstrainedNetworkAccess = configuration.allowsConstrainedNetworkAccess
        
        self.session = URLSession(configuration: config)
    }
}
