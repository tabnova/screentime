//
//  AppUsageTracker.swift
//  TabnovaEMM
//
//  Created on 2024
//

import Foundation

class AppUsageTracker: ObservableObject {
    static let shared = AppUsageTracker()

    private let userDefaults = UserDefaults(suiteName: "group.com.tabnova.enterprise")
    private let usageKey = "dailyAppUsage"

    struct AppUsageData: Codable {
        var packageName: String
        var date: String
        var totalMinutes: Int
        var totalSeconds: Int
        var lastUpdated: Date

        init(packageName: String, date: String) {
            self.packageName = packageName
            self.date = date
            self.totalMinutes = 0
            self.totalSeconds = 0
            self.lastUpdated = Date()
        }
    }

    private init() {
        logInfo("📊 AppUsageTracker initialized")
    }

    // MARK: - Get today's date string
    private func getTodayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // MARK: - Load all usage data
    private func loadUsageData() -> [String: AppUsageData] {
        guard let data = userDefaults?.data(forKey: usageKey),
              let decoded = try? JSONDecoder().decode([String: AppUsageData].self, from: data) else {
            return [:]
        }
        return decoded
    }

    // MARK: - Save usage data
    private func saveUsageData(_ data: [String: AppUsageData]) {
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults?.set(encoded, forKey: usageKey)
            logData("💾 Saved usage data for \(data.count) apps")
        }
    }

    // MARK: - Add usage time when threshold is hit
    func addUsageTime(packageName: String, thresholdMinutes: Int) {
        let today = getTodayDateString()
        var allUsageData = loadUsageData()

        let key = "\(packageName)_\(today)"

        if var existing = allUsageData[key] {
            // Update existing entry - SET total (threshold IS the cumulative total)
            let previousTotal = existing.totalMinutes
            existing.totalMinutes = thresholdMinutes  // ✅ SET to current total (not add)
            existing.totalSeconds = existing.totalMinutes * 60
            existing.lastUpdated = Date()
            allUsageData[key] = existing

            logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            logTime("⏱️  USAGE UPDATE")
            logApp("📱 App: \(packageName)")
            logTime("   Previous Total: \(previousTotal) min")
            logSuccess("   Current Total: \(existing.totalMinutes) min (\(existing.totalSeconds) sec)")
            logInfo("   📅 Date: \(today) (resets daily at midnight)")
            logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        } else {
            // Create new entry (first threshold hit today)
            var newUsage = AppUsageData(packageName: packageName, date: today)
            newUsage.totalMinutes = thresholdMinutes
            newUsage.totalSeconds = thresholdMinutes * 60
            allUsageData[key] = newUsage

            logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            logSuccess("🆕 FIRST USAGE TODAY")
            logApp("📱 App: \(packageName)")
            logTime("   Total Today: \(newUsage.totalMinutes) min (\(newUsage.totalSeconds) sec)")
            logInfo("   📅 Date: \(today)")
            logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }

        saveUsageData(allUsageData)
    }

    // MARK: - Get usage for a specific app today
    func getUsageForToday(packageName: String) -> AppUsageData? {
        let today = getTodayDateString()
        let allUsageData = loadUsageData()
        let key = "\(packageName)_\(today)"
        return allUsageData[key]
    }

    // MARK: - Get all usage data for today
    func getAllUsageForToday() -> [AppUsageData] {
        let today = getTodayDateString()
        let allUsageData = loadUsageData()

        return allUsageData.values.filter { $0.date == today }
    }

    // MARK: - Clear old data (older than 7 days)
    func clearOldData() {
        var allUsageData = loadUsageData()
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let initialCount = allUsageData.count
        allUsageData = allUsageData.filter { _, value in
            value.lastUpdated > sevenDaysAgo
        }

        let removed = initialCount - allUsageData.count
        if removed > 0 {
            saveUsageData(allUsageData)
            logInfo("🗑️ Cleared \(removed) old usage entries")
        }
    }
}
