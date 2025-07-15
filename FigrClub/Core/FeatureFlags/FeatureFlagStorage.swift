//
//  FeatureFlagStorage.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 15/7/25.
//

import Foundation

// MARK: - Feature Flag Storage Protocol
protocol FeatureFlagStorageProtocol: Sendable {
    func store(_ flags: [FeatureFlag]) async throws
    func loadFlags() async throws -> [FeatureFlag]
    func clearFlags() async throws
}

// MARK: - Feature Flag Storage Implementation
final class FeatureFlagStorage: FeatureFlagStorageProtocol, @unchecked Sendable {
    
    private let userDefaults: UserDefaults
    private let storageKey = "feature_flags_storage"
    private let queue = DispatchQueue(label: "com.figrclub.featureflags.storage", qos: .utility)
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func store(_ flags: [FeatureFlag]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                do {
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    let data = try encoder.encode(flags)
                    
                    self?.userDefaults.set(data, forKey: self?.storageKey ?? "")
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: FeatureFlagError.storageError(error.localizedDescription))
                }
            }
        }
    }
    
    func loadFlags() async throws -> [FeatureFlag] {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self,
                      let data = self.userDefaults.data(forKey: self.storageKey) else {
                    continuation.resume(returning: [])
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let flags = try decoder.decode([FeatureFlag].self, from: data)
                    continuation.resume(returning: flags)
                } catch {
                    continuation.resume(throwing: FeatureFlagError.storageError(error.localizedDescription))
                }
            }
        }
    }
    
    func clearFlags() async throws {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                self?.userDefaults.removeObject(forKey: self?.storageKey ?? "")
                continuation.resume()
            }
        }
    }
}
