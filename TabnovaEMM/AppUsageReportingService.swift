//
//  AppUsageReportingService.swift
//  TabnovaEMM
//
//  Created on 2024
//

import Foundation
import UIKit

class AppUsageReportingService {
    static let shared = AppUsageReportingService()

    private let apiURL = "https://b2b.novaemm.com:4500/api/v1/kids/application/usage/create"
    private let usageTracker = AppUsageTracker.shared

    struct UsageReportRequest: Codable {
        let email: String
        let profileId: String
        let serialNumber: String
        let batteryPercentage: Int
        let appVersion: String
        let applicationUsages: [ApplicationUsage]
    }

    struct ApplicationUsage: Codable {
        let packageName: String
        let date: String
        let createdOn: String
        let timeInMinute: Int
    }

    private init() {
        logInfo("🌐 AppUsageReportingService initialized")
    }

    // MARK: - Send usage report
    func sendUsageReport(packageName: String, thresholdMinutes: Int, completion: @escaping (Bool) -> Void) {
        logNetwork("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logNetwork("🌐 Sending Usage Report")
        logNetwork("Package: \(packageName)")
        logNetwork("Time: \(thresholdMinutes) min")

        // Get configuration
        let configManager = ManagedConfigManager.shared
        let email = configManager.email
        let profileId = configManager.profileId
        let serialNumber = configManager.serialNumber

        guard !email.isEmpty, !profileId.isEmpty, !serialNumber.isEmpty else {
            logError("❌ Missing required configuration (email, profileId, serialNumber)")
            completion(false)
            return
        }

        // Update usage tracker
        usageTracker.addUsageTime(packageName: packageName, thresholdMinutes: thresholdMinutes)

        // Get updated usage data
        guard let usageData = usageTracker.getUsageForToday(packageName: packageName) else {
            logError("❌ Failed to get usage data for \(packageName)")
            completion(false)
            return
        }

        // Get battery level
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryPercentage = Int(UIDevice.current.batteryLevel * 100)

        // Get app version
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

        // Get current date/time in ISO8601 format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: Date())

        let iso8601Formatter = ISO8601DateFormatter()
        let createdOn = iso8601Formatter.string(from: Date())

        // Create application usage entry
        let appUsage = ApplicationUsage(
            packageName: packageName,
            date: date,
            createdOn: createdOn,
            timeInMinute: usageData.totalMinutes
        )

        // Create request payload
        let requestPayload = UsageReportRequest(
            email: email,
            profileId: profileId,
            serialNumber: serialNumber,
            batteryPercentage: batteryPercentage,
            appVersion: appVersion,
            applicationUsages: [appUsage]
        )

        logData("📦 Request Payload:")
        logData("  Email: \(email)")
        logData("  ProfileId: \(profileId)")
        logData("  SerialNumber: \(serialNumber)")
        logData("  Battery: \(batteryPercentage)%")
        logData("  App Version: \(appVersion)")
        logData("  Package: \(packageName)")
        logData("  Date: \(date)")
        logData("  Total Time: \(usageData.totalMinutes) min (\(usageData.totalSeconds) sec)")

        // Send POST request
        sendPostRequest(payload: requestPayload, completion: completion)
    }

    // MARK: - Send POST request
    private func sendPostRequest(payload: UsageReportRequest, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: apiURL) else {
            logError("❌ Invalid API URL")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Get authorization token
        let authToken = ManagedConfigManager.shared.authorization
        if !authToken.isEmpty {
            request.setValue(authToken, forHTTPHeaderField: "Authorization")
            logKey("🔑 Authorization token added")
        }

        do {
            let jsonData = try JSONEncoder().encode(payload)
            request.httpBody = jsonData

            if let jsonString = String(data: jsonData, encoding: .utf8) {
                logData("📤 Request JSON:")
                logData(jsonString)
            }

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    logError("❌ Network error: \(error.localizedDescription)")
                    logNetwork("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    completion(false)
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    logNetwork("📥 Response Status: \(httpResponse.statusCode)")

                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        logNetwork("📥 Response Body: \(responseString)")
                    }

                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        logSuccess("✅ Usage report sent successfully")
                        logNetwork("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        completion(true)
                    } else {
                        logError("❌ Server returned error: \(httpResponse.statusCode)")
                        logNetwork("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        completion(false)
                    }
                } else {
                    logError("❌ No HTTP response")
                    logNetwork("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    completion(false)
                }
            }

            task.resume()
            logNetwork("🚀 Request sent to: \(apiURL)")

        } catch {
            logError("❌ JSON encoding error: \(error.localizedDescription)")
            logNetwork("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            completion(false)
        }
    }

    // MARK: - Send batch report for all apps
    func sendBatchUsageReport(completion: @escaping (Bool) -> Void) {
        logNetwork("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logNetwork("🌐 Sending Batch Usage Report")

        let allUsageData = usageTracker.getAllUsageForToday()

        if allUsageData.isEmpty {
            logWarning("⚠️ No usage data to report")
            completion(true)
            return
        }

        logInfo("📊 Found \(allUsageData.count) apps with usage data")

        // Get configuration
        let configManager = ManagedConfigManager.shared
        let email = configManager.email
        let profileId = configManager.profileId
        let serialNumber = configManager.serialNumber

        guard !email.isEmpty, !profileId.isEmpty, !serialNumber.isEmpty else {
            logError("❌ Missing required configuration")
            completion(false)
            return
        }

        // Get battery level
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryPercentage = Int(UIDevice.current.batteryLevel * 100)

        // Get app version
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

        // Create ISO8601 formatter
        let iso8601Formatter = ISO8601DateFormatter()

        // Build application usages array
        let appUsages = allUsageData.map { usage in
            ApplicationUsage(
                packageName: usage.packageName,
                date: usage.date,
                createdOn: iso8601Formatter.string(from: usage.lastUpdated),
                timeInMinute: usage.totalMinutes
            )
        }

        // Create request payload
        let requestPayload = UsageReportRequest(
            email: email,
            profileId: profileId,
            serialNumber: serialNumber,
            batteryPercentage: batteryPercentage,
            appVersion: appVersion,
            applicationUsages: appUsages
        )

        logData("📦 Batch Report Payload:")
        logData("  Apps: \(appUsages.count)")
        for usage in appUsages {
            logData("  - \(usage.packageName): \(usage.timeInMinute) min")
        }

        // Send POST request
        sendPostRequest(payload: requestPayload, completion: completion)
    }
}
