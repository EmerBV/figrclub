//
//  NetworkDispatcher.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 7/7/25.
//

import Foundation

// MARK: - Network Dispatcher Protocol
protocol NetworkDispatcherProtocol: Sendable {
    func dispatch<T: Codable>(_ endpoint: APIEndpoint) async throws -> T
    func dispatchData(_ endpoint: APIEndpoint) async throws -> Data
}

// MARK: - Network Dispatcher Implementation
final class NetworkDispatcher: NetworkDispatcherProtocol, @unchecked Sendable {
    
    // MARK: - Dependencies
    private let sessionProvider: URLSessionProviderProtocol
    private let tokenManager: TokenManager
    private let jsonDecoder: JSONDecoder
    
    // MARK: - Token Refresh Control
    private let refreshQueue = DispatchQueue(label: "com.figrclub.token-refresh", qos: .userInitiated)
    private var isRefreshingToken = false
    private var pendingRequests: [(CheckedContinuation<String, Error>)] = []
    
    // MARK: - Initialization
    init(sessionProvider: URLSessionProviderProtocol, tokenManager: TokenManager) {
        self.sessionProvider = sessionProvider
        self.tokenManager = tokenManager
        
        // Configure JSON Decoder with modern settings
        self.jsonDecoder = JSONDecoder()
        
        // Enhanced date decoding strategy
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        jsonDecoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            
            // Try different date formats
            if let dateString = try? container.decode(String.self) {
                // ISO8601 with fractional seconds
                if let date = ISO8601DateFormatter().date(from: dateString) {
                    return date
                }
                
                // Custom format
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                // Unix timestamp as string
                if let timestamp = Double(dateString) {
                    return Date(timeIntervalSince1970: timestamp)
                }
            }
            
            // Unix timestamp as number
            if let timestamp = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: timestamp)
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date")
        }
    }
    
    // MARK: - Public Methods
    
    func dispatch<T: Codable>(_ endpoint: APIEndpoint) async throws -> T {
        let data = try await dispatchData(endpoint)
        
        do {
            let result = try jsonDecoder.decode(T.self, from: data)
            return result
        } catch let decodingError as DecodingError {
            Logger.error("Decoding error for \(T.self): \(decodingError)")
            throw NetworkError.decodingError(decodingError)
        } catch {
            Logger.error("Unknown decoding error for \(T.self): \(error)")
            throw NetworkError.unknown(error)
        }
    }
    
    func dispatchData(_ endpoint: APIEndpoint) async throws -> Data {
        if endpoint.requiresAuth && !endpoint.isRefreshTokenEndpoint {
            return try await executeAuthenticatedRequest(endpoint)
        } else {
            return try await executeRequest(endpoint)
        }
    }
    
    // MARK: - Private Methods
    
    private func executeAuthenticatedRequest(_ endpoint: APIEndpoint) async throws -> Data {
        // First, try with current token
        do {
            return try await executeRequestWithCurrentToken(endpoint)
        } catch NetworkError.unauthorized {
            // Token might be expired, try to refresh
            let newToken = try await refreshTokenIfNeeded()
            
            // Retry with new token
            return try await executeRequestWithToken(endpoint, token: newToken)
        } catch {
            throw error
        }
    }
    
    private func executeRequestWithCurrentToken(_ endpoint: APIEndpoint) async throws -> Data {
        guard let token = await tokenManager.getToken() else {
            throw NetworkError.unauthorized
        }
        
        return try await executeRequestWithToken(endpoint, token: token)
    }
    
    private func executeRequestWithToken(_ endpoint: APIEndpoint, token: String) async throws -> Data {
        var request = try sessionProvider.createURLRequest(for: endpoint)
        
        // Add authorization header
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return try await executeRequestWithRetry(request, policy: endpoint.retryPolicy)
    }
    
    private func executeRequest(_ endpoint: APIEndpoint) async throws -> Data {
        let request = try sessionProvider.createURLRequest(for: endpoint)
        return try await executeRequestWithRetry(request, policy: endpoint.retryPolicy)
    }
    
    private func executeRequestWithRetry(_ request: URLRequest, policy: RetryPolicy) async throws -> Data {
        var lastError: Error?
        
        for attempt in 0...policy.maxRetries {
            do {
                let (data, response) = try await sessionProvider.dataTask(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                // Check if we should retry based on status code
                if attempt < policy.maxRetries && policy.retryableStatusCodes.contains(httpResponse.statusCode) {
                    Logger.warning("Request failed with status \(httpResponse.statusCode), retrying in \(policy.retryDelay)s")
                    try await Task.sleep(for: .seconds(policy.retryDelay))
                    continue
                }
                
                return try validateResponse(data: data, response: httpResponse)
                
            } catch let error as NetworkError {
                lastError = error
                
                // Don't retry on certain errors
                switch error {
                case .unauthorized, .forbidden, .notFound:
                    throw error
                default:
                    if attempt < policy.maxRetries {
                        Logger.warning("Request failed, retrying in \(policy.retryDelay)s: \(error)")
                        try await Task.sleep(for: .seconds(policy.retryDelay))
                        continue
                    }
                }
            } catch {
                lastError = error
                if attempt < policy.maxRetries {
                    Logger.warning("Request failed, retrying in \(policy.retryDelay)s: \(error)")
                    try await Task.sleep(for: .seconds(policy.retryDelay))
                    continue
                }
            }
        }
        
        throw lastError ?? NetworkError.unknown(NSError(domain: "UnknownError", code: -1))
    }
    
    // MARK: - Token Refresh Logic
    
    private func refreshTokenIfNeeded() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            refreshQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: NetworkError.unknown(NSError(domain: "SelfNil", code: -1)))
                    return
                }
                
                // If already refreshing, queue this request
                if self.isRefreshingToken {
                    self.pendingRequests.append(continuation)
                    return
                }
                
                // Start refresh process
                self.isRefreshingToken = true
                
                Task {
                    do {
                        let newToken = try await self.performTokenRefresh()
                        
                        await MainActor.run {
                            // Resume all pending requests
                            self.refreshQueue.async {
                                for pendingContinuation in self.pendingRequests {
                                    pendingContinuation.resume(returning: newToken)
                                }
                                self.pendingRequests.removeAll()
                                self.isRefreshingToken = false
                            }
                        }
                        
                        continuation.resume(returning: newToken)
                        
                    } catch {
                        await MainActor.run {
                            // Fail all pending requests
                            self.refreshQueue.async {
                                for pendingContinuation in self.pendingRequests {
                                    pendingContinuation.resume(throwing: error)
                                }
                                self.pendingRequests.removeAll()
                                self.isRefreshingToken = false
                            }
                        }
                        
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    private func performTokenRefresh() async throws -> String {
        let refreshEndpoint = AuthEndpoints.refreshToken
        
        // ✅ Get DTO response (which is Codable)
        let responseDTO: AuthResponseDTO = try await dispatch(refreshEndpoint)
        
        // ✅ Extract token from DTO
        let newToken = responseDTO.data.authToken.token
        
        // Save new token
        await tokenManager.saveToken(newToken)
        
        return newToken
    }
    
    // MARK: - Response Validation
    
    private func validateResponse(data: Data, response: HTTPURLResponse) throws -> Data {
        switch response.statusCode {
        case 200...299:
            return data
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 400...499:
            let apiError = try? jsonDecoder.decode(ErrorResponseDTO.self, from: data)
            throw NetworkError.badRequest(convertDTOToAPIError(apiError))
        case 500...599:
            let apiError = try? jsonDecoder.decode(ErrorResponseDTO.self, from: data)
            throw NetworkError.serverError(convertDTOToAPIError(apiError))
        default:
            throw NetworkError.unknown(NSError(domain: "HTTPError", code: response.statusCode, userInfo: nil))
        }
    }
    
    private func convertDTOToAPIError(_ errorDTO: ErrorResponseDTO?) -> APIError? {
        guard let errorDTO = errorDTO else { return nil }
        
        return APIError(
            message: errorDTO.data.message,
            code: errorDTO.data.code,
            details: errorDTO.data.details
        )
    }
}
