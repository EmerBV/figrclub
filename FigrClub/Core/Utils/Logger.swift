//
//  Logger.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import OSLog
import os
import FirebaseAnalytics
import FirebaseCrashlytics

#if canImport(Darwin)
import Darwin.Mach
#endif

// MARK: - Logger
final class Logger {
    static let shared = Logger()
    
    private let osLogger: OSLog
    private let subsystem = "com.emerbv.FigrClub"
    
    // DateFormatter for logging timestamps
    private static let logTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    private init() {
        self.osLogger = OSLog(subsystem: subsystem, category: "general")
    }
    
    // MARK: - Log Levels
    enum LogLevel: String, CaseIterable {
        case verbose = "VERBOSE"
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case fatal = "FATAL"
        
        var osLogType: OSLogType {
            switch self {
            case .verbose, .debug:
                return .debug
            case .info:
                return .info
            case .warning:
                return .default
            case .error, .fatal:
                return .error
            }
        }
        
        var emoji: String {
            switch self {
            case .verbose:
                return "💬"
            case .debug:
                return "🐛"
            case .info:
                return "ℹ️"
            case .warning:
                return "⚠️"
            case .error:
                return "❌"
            case .fatal:
                return "💀"
            }
        }
    }
    
    // MARK: - Logging Methods
    func verbose(
        _ message: String,
        category: String = "general",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.verbose, message: message, category: category, file: file, function: function, line: line)
    }
    
    func debug(
        _ message: String,
        category: String = "general",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.debug, message: message, category: category, file: file, function: function, line: line)
    }
    
    func info(
        _ message: String,
        category: String = "general",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.info, message: message, category: category, file: file, function: function, line: line)
    }
    
    func warning(
        _ message: String,
        category: String = "general",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.warning, message: message, category: category, file: file, function: function, line: line)
    }
    
    func error(
        _ message: String,
        error: Error? = nil,
        category: String = "general",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += " Error: \(error.localizedDescription)"
        }
        
        log(.error, message: fullMessage, category: category, file: file, function: function, line: line)
        
        // Send to Crashlytics
        if AppConfig.FeatureFlags.enableCrashReporting {
            Crashlytics.crashlytics().log(fullMessage)
            if let error = error {
                Crashlytics.crashlytics().record(error: error)
            }
        }
    }
    
    func fatal(
        _ message: String,
        error: Error? = nil,
        category: String = "general",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += " Error: \(error.localizedDescription)"
        }
        
        log(.fatal, message: fullMessage, category: category, file: file, function: function, line: line)
        
        // Send to Crashlytics
        if AppConfig.FeatureFlags.enableCrashReporting {
            Crashlytics.crashlytics().log(fullMessage)
            if let error = error {
                Crashlytics.crashlytics().record(error: error)
            }
        }
    }
    
    // MARK: - Private Methods
    private func log(
        _ level: LogLevel,
        message: String,
        category: String,
        file: String,
        function: String,
        line: Int
    ) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let formattedMessage = formatMessage(
            level: level,
            message: message,
            category: category,
            fileName: fileName,
            function: function,
            line: line
        )
        
        // Console logging (only in debug)
#if DEBUG
        print(formattedMessage)
#endif
        
        // OSLog
        let categoryLogger = OSLog(subsystem: subsystem, category: category)
        os_log("%{public}@", log: categoryLogger, type: level.osLogType, formattedMessage)
    }
    
    private func formatMessage(
        level: LogLevel,
        message: String,
        category: String,
        fileName: String,
        function: String,
        line: Int
    ) -> String {
        let timestamp = Self.logTimestampFormatter.string(from: Date())
        return "\(level.emoji) [\(timestamp)] [\(level.rawValue)] [\(category)] [\(fileName):\(line)] \(function) - \(message)"
    }
    
    // Network logging
    func logNetworkRequest(
        method: String,
        url: String,
        statusCode: Int? = nil,
        duration: TimeInterval? = nil
    ) {
        var message = "🌐 \(method) \(url)"
        
        if let statusCode = statusCode {
            message += " [\(statusCode)]"
        }
        
        if let duration = duration {
            message += " (\(String(format: "%.2f", duration))s)"
        }
        
        if let statusCode = statusCode, statusCode >= 400 {
            error(message, category: "network")
        } else {
            info(message, category: "network")
        }
    }
    
    // Authentication logging
    func logAuthEvent(_ event: String, success: Bool = true) {
        let message = "🔐 Auth: \(event)"
        if success {
            info(message, category: "auth")
        } else {
            warning("\(message) - Failed", category: "auth")
        }
    }
    
    // UI logging
    func logUIEvent(_ event: String, screen: String) {
        info("🎨 UI: \(event) on \(screen)", category: "ui")
    }
    
    // Data logging
    func logDataOperation(_ operation: String, entityType: String, success: Bool = true) {
        let message = "💾 Data: \(operation) \(entityType)"
        if success {
            info(message, category: "data")
        } else {
            error(message, category: "data")
        }
    }
    
    // User actions logging
    func logUserAction(
        action: String,
        category: String = "user_action",
        metadata: [String: Any]? = nil
    ) {
        var message = "👤 User action: \(action)"
        if let metadata = metadata {
            message += " \(metadata)"
        }
        
        info(message, category: category)
    }
    
    // Memory usage logging
    func logMemoryUsage(category: String = "memory") {
#if canImport(Darwin)
        var memoryInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsage = memoryInfo.resident_size / (1024 * 1024) // MB
            info("📊 Memory usage: \(memoryUsage) MB", category: category)
        } else {
            info("📊 Memory usage: Unable to retrieve", category: category)
        }
#else
        info("📊 Memory usage: Not available on this platform", category: category)
#endif
    }
}

// MARK: - Apple Logger Extensions (iOS 14+)
@available(iOS 14.0, *)
extension os.Logger {
    static let network = os.Logger(subsystem: "com.emerbv.FigrClub", category: "network")
    static let auth = os.Logger(subsystem: "com.emerbv.FigrClub", category: "auth")
    static let ui = os.Logger(subsystem: "com.emerbv.FigrClub", category: "ui")
    static let data = os.Logger(subsystem: "com.emerbv.FigrClub", category: "data")
    static let performance = os.Logger(subsystem: "com.emerbv.FigrClub", category: "performance")
}

// MARK: - Logger Categories
extension Logger {
    struct Category {
        static let general = "general"
        static let network = "network"
        static let authentication = "authentication"
        static let coredata = "coredata"
        static let ui = "ui"
        static let notifications = "notifications"
        static let firebase = "firebase"
        static let kingfisher = "kingfisher"
        static let analytics = "analytics"
        static let performance = "performance"
        static let memory = "memory"
        static let userAction = "user_action"
        static let lifecycle = "lifecycle"
    }
}
