//
//  Publisher+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Combine

extension Publisher {
    /// Converts Publisher to async/await
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = first()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                        cancellable?.cancel()
                    }
                )
        }
    }
    
    /// Retry with exponential backoff
    func retryWithBackoff(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0
    ) -> AnyPublisher<Output, Failure> {
        self.catch { error -> AnyPublisher<Output, Failure> in
            return Publishers.Sequence(sequence: 0..<maxRetries)
                .publisher
                .flatMap { attempt in
                    return Just(())
                        .delay(for: .seconds(baseDelay * pow(2.0, Double(attempt))), scheduler: DispatchQueue.main)
                        .flatMap { _ in self }
                }
                .first()
                .catch { _ in Fail(error: error) }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}

extension Published.Publisher {
    /// Debounce and remove duplicates
    func debounceAndRemoveDuplicates(
        for interval: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(300)
    ) -> AnyPublisher<Output, Failure> where Output: Equatable {
        self
            .debounce(for: interval, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
