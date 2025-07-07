//
//  URL+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation

extension URL {
    /// Validates if URL is reachable
    var isReachable: Bool {
        guard let url = URL(string: self.absoluteString) else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0
        
        let semaphore = DispatchSemaphore(value: 0)
        var isReachable = false
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse {
                isReachable = httpResponse.statusCode == 200
            }
            semaphore.signal()
        }.resume()
        
        semaphore.wait()
        return isReachable
    }
}
