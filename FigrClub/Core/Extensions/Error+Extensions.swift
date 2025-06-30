//
//  Error+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation

extension Error {
    var localizedDescription: String {
        if let apiError = self as? APIError {
            return apiError.message
        }
        return (self as NSError).localizedDescription
    }
    
    var isNetworkError: Bool {
        if let urlError = self as? URLError {
            return [.notConnectedToInternet, .timedOut, .cannotConnectToHost].contains(urlError.code)
        }
        return false
    }
}
