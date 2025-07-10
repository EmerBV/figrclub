//
//  APIServiceAdapter.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 10/7/25.
//

import Foundation

/*
 // MARK: - API Service Adapter (Backward Compatibility)
 final class APIServiceAdapter: APIServiceProtocol, @unchecked Sendable {
 private let networkDispatcher: NetworkDispatcherProtocol
 
 init(networkDispatcher: NetworkDispatcherProtocol) {
 self.networkDispatcher = networkDispatcher
 }
 
 func request<T: Codable>(_ endpoint: Endpoint) async throws -> T {
 return try await networkDispatcher.dispatch(endpoint)
 }
 
 func requestData(_ endpoint: Endpoint) async throws -> Data {
 return try await networkDispatcher.dispatchData(endpoint)
 }
 
 func dispatch<T: Codable>(_ endpoint: Endpoint) async throws -> T {
 return try await networkDispatcher.dispatch(endpoint)
 }
 }
 */
