//
//  Publisher+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import Combine

extension Publisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var finished = false
            
            cancellable = self.sink(
                receiveCompletion: { completion in
                    if !finished {
                        finished = true
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    }
                },
                receiveValue: { value in
                    if !finished {
                        finished = true
                        continuation.resume(returning: value)
                        cancellable?.cancel()
                    }
                }
            )
        }
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
