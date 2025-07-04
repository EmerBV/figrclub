//
//  APIRequest.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 2/7/25.
//

import Foundation

struct LoginRequest: Codable {
    let email: String
    let password: String
}
