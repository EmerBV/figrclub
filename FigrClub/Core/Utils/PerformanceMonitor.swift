//
//  PerformanceMonitor.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
/*
 final class PerformanceMonitor {
 static let shared = PerformanceMonitor()
 
 private var startTimes: [String: CFAbsoluteTime] = [:]
 private let queue = DispatchQueue(label: "com.figrclub.performance", attributes: .concurrent)
 
 private init() {}
 
 func startTimer(for operation: String) {
 queue.async(flags: .barrier) {
 self.startTimes[operation] = CFAbsoluteTimeGetCurrent()
 }
 }
 
 func endTimer(for operation: String) {
 queue.async(flags: .barrier) {
 guard let startTime = self.startTimes[operation] else {
 Logger.shared.warning("No start time found for operation: \(operation)", category: "performance")
 return
 }
 
 let duration = CFAbsoluteTimeGetCurrent() - startTime
 self.startTimes.removeValue(forKey: operation)
 
 DispatchQueue.main.async {
 Logger.shared.info("⏱️ \(operation): \(String(format: "%.3f", duration))s", category: "performance")
 Analytics.shared.logPerformance(operation: operation, duration: duration)
 }
 }
 }
 
 func measureTime<T>(
 operation: String,
 execute: () throws -> T
 ) rethrows -> T {
 let startTime = CFAbsoluteTimeGetCurrent()
 let result = try execute()
 let duration = CFAbsoluteTimeGetCurrent() - startTime
 
 Logger.shared.info("⏱️ \(operation): \(String(format: "%.3f", duration))s", category: "performance")
 Analytics.shared.logPerformance(operation: operation, duration: duration)
 
 return result
 }
 
 func measureTimeAsync<T>(
 operation: String,
 execute: () async throws -> T
 ) async rethrows -> T {
 let startTime = CFAbsoluteTimeGetCurrent()
 let result = try await execute()
 let duration = CFAbsoluteTimeGetCurrent() - startTime
 
 Logger.shared.info("⏱️ \(operation): \(String(format: "%.3f", duration))s", category: "performance")
 Analytics.shared.logPerformance(operation: operation, duration: duration)
 
 return result
 }
 }
 */
