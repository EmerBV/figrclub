//
//  Logger.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 3/7/25.
//

import Foundation
import OSLog
import FirebaseCrashlytics

// MARK: - Logger
final class Logger {
    static let shared = Logger()
    
    private let osLog: OSLog
    private let subsystem = Bundle.main.bundleIdentifier ?? "com.figrclub"
    
    private init() {
        self.osLog = OSLog(subsystem: subsystem, category: "general")
    }
    
    // MARK: - Log Levels
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case fatal = "FATAL"
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .fatal: return .fault
            }
        }
    }
    
    // MARK: - Public Methods
    func debug(_ message: String, category: String = "general") {
        log(level: .debug, message: message, category: category)
    }
    
    func info(_ message: String, category: String = "general") {
        log(level: .info, message: message, category: category)
    }
    
    func warning(_ message: String, category: String = "general") {
        log(level: .warning, message: message, category: category)
    }
    
    func error(_ message: String, error: Error? = nil, category: String = "general") {
        var logMessage = message
        if let error = error {
            logMessage += " - Error: \(error.localizedDescription)"
        }
        log(level: .error, message: logMessage, category: category)
        
        // Enviar a Crashlytics en producción
#if !DEBUG
        if let error = error {
            Crashlytics.crashlytics().record(error: error)
        }
#endif
    }
    
    func fatal(_ message: String, category: String = "general") {
        log(level: .fatal, message: message, category: category)
        
        // En producción, registrar como error crítico en Crashlytics
#if !DEBUG
        let userInfo = [NSLocalizedDescriptionKey: message]
        let error = NSError(domain: subsystem, code: -1, userInfo: userInfo)
        Crashlytics.crashlytics().record(error: error)
#endif
    }
    
    // MARK: - Private Methods
    private func log(level: LogLevel, message: String, category: String) {
        let categoryLog = OSLog(subsystem: subsystem, category: category)
        let formattedMessage = "[\(level.rawValue)] \(message)"
        
        os_log("%{public}@", log: categoryLog, type: level.osLogType, formattedMessage)
        
        // En debug, también imprimir en consola
#if DEBUG
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] [\(level.rawValue)] [\(category)] \(message)")
#endif
    }
}
