//
//  DebugLogger.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import SwiftUI

// MARK: - Debug Logger (Debug builds only)
#if DEBUG
final class DebugLogger {
    static let shared = DebugLogger()
    private var logs: [LogEntry] = []
    private let maxLogs = 1000
    
    struct LogEntry {
        let timestamp: Date
        let level: Logger.LogLevel
        let message: String
        let category: String
        let file: String
        let function: String
        let line: Int
    }
    
    private init() {}
    
    func addLog(
        level: Logger.LogLevel,
        message: String,
        category: String,
        file: String,
        function: String,
        line: Int
    ) {
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            message: message,
            category: category,
            file: file,
            function: function,
            line: line
        )
        
        logs.append(entry)
        
        // Keep only the last maxLogs entries
        if logs.count > maxLogs {
            logs.removeFirst(logs.count - maxLogs)
        }
    }
    
    func getLogs(level: Logger.LogLevel? = nil, category: String? = nil) -> [LogEntry] {
        var filteredLogs = logs
        
        if let level = level {
            filteredLogs = filteredLogs.filter { $0.level == level }
        }
        
        if let category = category {
            filteredLogs = filteredLogs.filter { $0.category == category }
        }
        
        return filteredLogs.reversed() // Most recent first
    }
    
    func clearLogs() {
        logs.removeAll()
    }
    
    func exportLogs() -> String {
        return logs.map { entry in
            let timestamp = DateFormatter.logTimestamp.string(from: entry.timestamp)
            let fileName = URL(fileURLWithPath: entry.file).lastPathComponent
            return "\(entry.level.emoji) [\(timestamp)] [\(entry.level.rawValue)] [\(entry.category)] [\(fileName):\(entry.line)] \(entry.function) - \(entry.message)"
        }.joined(separator: "\n")
    }
}

struct DebugLogsView: View {
    @State private var logs: [DebugLogger.LogEntry] = []
    @State private var selectedLevel: Logger.LogLevel?
    @State private var selectedCategory: String?
    @State private var showExportSheet = false
    @State private var exportedLogs = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Filters
                HStack {
                    Picker("Level", selection: $selectedLevel) {
                        Text("All").tag(Logger.LogLevel?.none)
                        ForEach(Logger.LogLevel.allCases, id: \.self) { level in
                            Text("\(level.emoji) \(level.rawValue)").tag(level as Logger.LogLevel?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Spacer()
                    
                    Button("Clear") {
                        DebugLogger.shared.clearLogs()
                        refreshLogs()
                    }
                    
                    Button("Export") {
                        exportedLogs = DebugLogger.shared.exportLogs()
                        showExportSheet = true
                    }
                }
                .padding()
                
                // Logs List
                List(logs, id: \.timestamp) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(log.level.emoji)
                            Text(log.category)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)
                            Spacer()
                            Text(log.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(log.message)
                            .font(.footnote)
                        
                        Text("\(URL(fileURLWithPath: log.file).lastPathComponent):\(log.line)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("Debug Logs")
            .onAppear {
                refreshLogs()
            }
            .onChange(of: selectedLevel) { _ in
                refreshLogs()
            }
            .onChange(of: selectedCategory) { _ in
                refreshLogs()
            }
            .sheet(isPresented: $showExportSheet) {
                NavigationView {
                    ScrollView {
                        Text(exportedLogs)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                    }
                    .navigationTitle("Exported Logs")
                    .navigationBarItems(
                        leading: Button("Close") { showExportSheet = false },
                        trailing: Button("Share") {
                            let activityVC = UIActivityViewController(
                                activityItems: [exportedLogs],
                                applicationActivities: nil
                            )
                            UIApplication.shared.topViewController?.present(activityVC, animated: true)
                        }
                    )
                }
            }
        }
    }
    
    private func refreshLogs() {
        logs = DebugLogger.shared.getLogs(level: selectedLevel, category: selectedCategory)
    }
}
#endif

