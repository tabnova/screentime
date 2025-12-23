import Foundation
import Combine

class LogManager: ObservableObject {
    static let shared = LogManager()

    @Published var logs: [LogEntry] = []
    private let maxLogs = 500 // Keep last 500 log entries
    private let dateFormatter: DateFormatter

    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let level: LogLevel

        var formattedTimestamp: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return formatter.string(from: timestamp)
        }
    }

    enum LogLevel: String {
        case info = "ℹ️"
        case success = "✅"
        case warning = "⚠️"
        case error = "❌"
        case debug = "🔍"
        case network = "🌐"
        case key = "🔑"
        case data = "📦"
        case app = "📱"
        case time = "⏱️"
        case event = "🔔"
    }

    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
    }

    func log(_ message: String, level: LogLevel = .info) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let entry = LogEntry(timestamp: Date(), message: message, level: level)
            self.logs.append(entry)

            // Keep only the most recent logs
            if self.logs.count > self.maxLogs {
                self.logs.removeFirst(self.logs.count - self.maxLogs)
            }

            // Also print to console
            print("\(level.rawValue) [\(entry.formattedTimestamp)] \(message)")
        }
    }

    func clearLogs() {
        DispatchQueue.main.async { [weak self] in
            self?.logs.removeAll()
        }
    }

    func exportLogs() -> String {
        return logs.map { "\(self.dateFormatter.string(from: $0.timestamp)) [\($0.level.rawValue)] \($0.message)" }
            .joined(separator: "\n")
    }
}

// Global logging functions for convenience
func logInfo(_ message: String) {
    LogManager.shared.log(message, level: .info)
}

func logSuccess(_ message: String) {
    LogManager.shared.log(message, level: .success)
}

func logWarning(_ message: String) {
    LogManager.shared.log(message, level: .warning)
}

func logError(_ message: String) {
    LogManager.shared.log(message, level: .error)
}

func logDebug(_ message: String) {
    LogManager.shared.log(message, level: .debug)
}

func logNetwork(_ message: String) {
    LogManager.shared.log(message, level: .network)
}

func logKey(_ message: String) {
    LogManager.shared.log(message, level: .key)
}

func logData(_ message: String) {
    LogManager.shared.log(message, level: .data)
}

func logApp(_ message: String) {
    LogManager.shared.log(message, level: .app)
}

func logTime(_ message: String) {
    LogManager.shared.log(message, level: .time)
}

func logEvent(_ message: String) {
    LogManager.shared.log(message, level: .event)
}
