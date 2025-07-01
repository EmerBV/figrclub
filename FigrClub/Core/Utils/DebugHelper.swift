//
//  DebugHelper.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 1/7/25.
//

import Foundation

#if DEBUG
struct DebugHelper {
    
    static func printDecodingError(_ error: DecodingError) {
        switch error {
        case .dataCorrupted(let context):
            print("❌ Data corrupted: \(context.debugDescription)")
            print("🔍 Coding path: \(context.codingPath)")
            
        case .keyNotFound(let key, let context):
            print("❌ Key '\(key.stringValue)' not found")
            print("🔍 Context: \(context.debugDescription)")
            print("🔍 Coding path: \(context.codingPath)")
            
        case .typeMismatch(let type, let context):
            print("❌ Type mismatch. Expected \(type)")
            print("🔍 Context: \(context.debugDescription)")
            print("🔍 Coding path: \(context.codingPath)")
            
        case .valueNotFound(let type, let context):
            print("❌ Value of type \(type) not found")
            print("🔍 Context: \(context.debugDescription)")
            print("🔍 Coding path: \(context.codingPath)")
            
        @unknown default:
            print("❌ Unknown decoding error: \(error)")
        }
    }
    
    static func validateJSON<T: Codable>(_ jsonString: String, as type: T.Type) -> Bool {
        guard let data = jsonString.data(using: .utf8) else {
            print("❌ Invalid JSON string")
            return false
        }
        
        do {
            let _ = try JSONDecoder().decode(type, from: data)
            print("✅ JSON is valid for type \(type)")
            return true
        } catch let decodingError as DecodingError {
            print("❌ JSON validation failed for type \(type)")
            printDecodingError(decodingError)
            return false
        } catch {
            print("❌ JSON validation failed: \(error)")
            return false
        }
    }
    
    static func inspectJSONStructure(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else {
            print("❌ Invalid JSON string")
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            print("🔍 JSON Structure:")
            print(json)
            
            if let dict = json as? [String: Any] {
                print("🔍 Top-level keys: \(dict.keys)")
                
                // Check if it's a wrapped response
                if dict.keys.contains("data") {
                    print("📦 Detected wrapped response (has 'data' key)")
                    if let dataValue = dict["data"] {
                        print("🔍 Data content type: \(type(of: dataValue))")
                    }
                }
                
                if dict.keys.contains("message") {
                    print("📝 Has message: \(dict["message"] ?? "nil")")
                }
                
                if dict.keys.contains("status") {
                    print("📊 Has status: \(dict["status"] ?? "nil")")
                }
            }
            
        } catch {
            print("❌ Failed to parse JSON: \(error)")
        }
    }
}

// Extension para el NetworkManager para debugging
extension NetworkManager {
    func debugRequest<T: Codable>(
        endpoint: APIEndpoint,
        expectedType: T.Type,
        body: Codable? = nil
    ) {
#if DEBUG
        print("🐛 DEBUG REQUEST")
        print("📍 Endpoint: \(endpoint.path)")
        print("🔧 Method: \(endpoint.method.rawValue)")
        print("🎯 Expected Type: \(expectedType)")
        
        if let queryParams = endpoint.queryParameters {
            print("📋 Query Parameters: \(queryParams)")
        }
        
        if let body = body {
            do {
                let bodyData = try JSONEncoder().encode(body)
                if let bodyString = String(data: bodyData, encoding: .utf8) {
                    print("📤 Request Body: \(bodyString)")
                }
            } catch {
                print("❌ Failed to encode body for debugging: \(error)")
            }
        }
#endif
    }
}
#endif
