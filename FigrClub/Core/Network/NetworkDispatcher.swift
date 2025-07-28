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
        
        // Single date decoding strategy
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            
            // Try timestamp (number) first
            if let timestamp = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: timestamp / 1000.0)
            }
            
            // Try string formats
            if let dateString = try? container.decode(String.self) {
                // ISO8601 with milliseconds
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                // ISO8601 basic
                if let date = ISO8601DateFormatter().date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date from provided value"
            )
        }
        
        Logger.debug("✅ NetworkDispatcher: Initialized with simplified date decoding")
    }
    
    // MARK: - Public Methods
    func dispatch<T: Codable>(_ endpoint: APIEndpoint) async throws -> T {
        let data = try await dispatchData(endpoint)
        
        do {
            let result = try jsonDecoder.decode(T.self, from: data)
            Logger.debug("✅ NetworkDispatcher: Successfully decoded \(T.self)")
            return result
        } catch let decodingError as DecodingError {
            Logger.error("❌ NetworkDispatcher: Decoding error for \(T.self): \(decodingError)")
            
            // Log detailed decoding error for debugging
            switch decodingError {
            case .typeMismatch(let type, let context):
                Logger.error("Type mismatch: Expected \(type), context: \(context)")
            case .valueNotFound(let type, let context):
                Logger.error("Value not found: \(type), context: \(context)")
            case .keyNotFound(let key, let context):
                Logger.error("Key not found: \(key), context: \(context)")
            case .dataCorrupted(let context):
                Logger.error("Data corrupted: \(context)")
            @unknown default:
                Logger.error("Unknown decoding error: \(decodingError)")
            }
            
            throw NetworkError.decodingError(decodingError)
        } catch {
            Logger.error("❌ NetworkDispatcher: Unknown decoding error for \(T.self): \(error)")
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
        
        // 🔧 DEBUG: Log request details for debugging physical device issues
        Logger.debug("🌐 NetworkDispatcher: Executing request to: \(request.url?.absoluteString ?? "unknown")")
        Logger.debug("📱 NetworkDispatcher: Target Environment: \(AppConfig.shared.environment.displayName)")
        #if targetEnvironment(simulator)
        Logger.debug("📱 Running on: Simulator")
        #else
        Logger.debug("📱 Running on: Physical Device")
        #endif
        
        for attempt in 0...policy.maxRetries {
            do {
                Logger.debug("🔄 NetworkDispatcher: Attempt \(attempt + 1)/\(policy.maxRetries + 1) for \(request.url?.path ?? "unknown")")
                
                let startTime = Date()
                let (data, response) = try await sessionProvider.dataTask(for: request)
                let duration = Date().timeIntervalSince(startTime)
                
                Logger.debug("⏱️ NetworkDispatcher: Request completed in \(String(format: "%.2f", duration))s")
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    Logger.error("❌ NetworkDispatcher: Invalid response type")
                    throw NetworkError.invalidResponse
                }
                
                Logger.debug("📡 NetworkDispatcher: Response status: \(httpResponse.statusCode)")
                
                // Check if we should retry based on status code
                if attempt < policy.maxRetries && policy.retryableStatusCodes.contains(httpResponse.statusCode) {
                    Logger.warning("⚠️ NetworkDispatcher: Request failed with status \(httpResponse.statusCode), retrying in \(policy.retryDelay)s")
                    try await Task.sleep(for: .seconds(policy.retryDelay))
                    continue
                }
                
                return try validateResponse(data: data, response: httpResponse)
                
            } catch let error as NetworkError {
                lastError = error
                Logger.error("❌ NetworkDispatcher: NetworkError on attempt \(attempt + 1): \(error.localizedDescription)")
                
                // Don't retry on certain errors
                switch error {
                case .unauthorized, .forbidden, .notFound:
                    Logger.debug("🚫 NetworkDispatcher: Non-retryable error, throwing immediately")
                    throw error
                default:
                    if attempt < policy.maxRetries {
                        Logger.warning("🔄 NetworkDispatcher: Retryable error, retrying in \(policy.retryDelay)s: \(error)")
                        try await Task.sleep(for: .seconds(policy.retryDelay))
                        continue
                    }
                }
            } catch {
                lastError = error
                Logger.error("❌ NetworkDispatcher: Generic error on attempt \(attempt + 1): \(error.localizedDescription)")
                
                // 🔧 DEBUG: Especial handling for connection errors on physical devices
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .cannotConnectToHost:
                        Logger.error("🔌 NetworkDispatcher: Cannot connect to host - Check if server is running and accessible from device")
                    case .timedOut:
                        Logger.error("⏰ NetworkDispatcher: Request timed out - Check network connectivity")
                    case .notConnectedToInternet:
                        Logger.error("📡 NetworkDispatcher: No internet connection")
                    default:
                        Logger.error("🌐 NetworkDispatcher: URLError: \(urlError.localizedDescription)")
                    }
                }
                
                if attempt < policy.maxRetries {
                    Logger.warning("🔄 NetworkDispatcher: Generic error, retrying in \(policy.retryDelay)s: \(error)")
                    try await Task.sleep(for: .seconds(policy.retryDelay))
                    continue
                }
            }
        }
        
        Logger.error("💥 NetworkDispatcher: All retry attempts failed. Final error: \(lastError?.localizedDescription ?? "Unknown")")
        throw lastError ?? NetworkError.unknown(NSError(domain: "UnknownError", code: -1))
    }
    
    // MARK: - Token Refresh Logic (unchanged)
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
        
        // Get DTO response (which is Codable)
        let responseDTO: AuthResponseDTO = try await dispatch(refreshEndpoint)
        
        // Extract token from DTO
        let newToken = responseDTO.data.authToken.token
        
        // Save new token
        await tokenManager.saveToken(newToken)
        
        return newToken
    }
    
    // MARK: - Response Validation
    func validateResponse(data: Data, response: HTTPURLResponse) throws -> Data {
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
