//
//  NetworkLoggerProtocol.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 4/7/25.
//

import Foundation

protocol NetworkLoggerProtocol {
    func logRequest(_ request: URLRequest)
    func logResponse(_ response: URLResponse?, data: Data?, error: Error?)
}

final class NetworkLogger: NetworkLoggerProtocol {
    func logRequest(_ request: URLRequest) {
        Logger.shared.debug("Network Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "Unknown URL")", category: "network")
    }
    
    func logResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        if let error = error {
            Logger.shared.error("Network Error", error: error, category: "network")
        } else if let httpResponse = response as? HTTPURLResponse {
            Logger.shared.debug("Network Response: \(httpResponse.statusCode)", category: "network")
        }
    }
}

