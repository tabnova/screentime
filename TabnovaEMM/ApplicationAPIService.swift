import Foundation
import Combine

struct APIResponse: Codable {
    let applications: [ApplicationResponse]?
    let data: [ApplicationResponse]?
}

struct ApplicationResponse: Codable {
    let packageName: String
    let dailyLimitTimeNumber: Int?  // Can be null
    let usedLimit: Int?  // Can be null
    let displayText: String?  // App display name

    enum CodingKeys: String, CodingKey {
        case packageName = "package_name"
        case dailyLimitTimeNumber = "dailyLimitTimeNumber"
        case usedLimit = "usedLimit"
        case displayText = "display_text"
    }
}

class ApplicationAPIService: ObservableObject {
    @Published var applications: [ApplicationData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let configManager = ManagedConfigManager.shared
    private let usageReporter = AppUsageReportingService.shared
    private let usageTracker = AppUsageTracker.shared
    private var processedEventIds: Set<String> = []

    func fetchApplicationList() {
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logNetwork("📡 FETCH APPLICATION LIST BUTTON PRESSED")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        guard !configManager.profileId.isEmpty else {
            errorMessage = "Profile ID is not set in managed configuration"
            logError("❌ Profile ID is not set")
            logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            return
        }

        guard !configManager.authorization.isEmpty else {
            errorMessage = "Authorization token is not set in managed configuration"
            logError("❌ Authorization token is not set")
            logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            return
        }

        isLoading = true
        errorMessage = nil

        let urlString = "https://b2b.novaemm.com:4500/api/v1/admin/device-profile/application/list?profile_id=\(configManager.profileId)&type=GET"

        logNetwork("🌐 Making GET Request")
        logData("📍 URL: \(urlString)")
        logKey("🔑 Authorization: ***\(String(configManager.authorization.suffix(20)))")
        logInfo("🔧 Profile ID: \(configManager.profileId)")

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            logError("❌ Invalid URL: \(urlString)")
            logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(configManager.authorization, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        logInfo("🚀 Sending request...")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                logNetwork("📥 RECEIVED RESPONSE")
                logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    logError("❌ Network error: \(error.localizedDescription)")
                    logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    logNetwork("📊 HTTP Status Code: \(httpResponse.statusCode)")
                    logData("📋 Response Headers: \(httpResponse.allHeaderFields)")

                    guard (200...299).contains(httpResponse.statusCode) else {
                        self?.errorMessage = "Server error: HTTP \(httpResponse.statusCode)"
                        logError("❌ Server returned error status: \(httpResponse.statusCode)")

                        if let data = data, let errorBody = String(data: data, encoding: .utf8) {
                            logError("📄 Error Response Body: \(errorBody)")
                        }

                        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        return
                    }
                }

                guard let data = data else {
                    self?.errorMessage = "No data received"
                    logError("❌ No data received from server")
                    logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    return
                }

                logSuccess("✅ Received data: \(data.count) bytes")

                // Log raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    logData("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    logData("📄 Raw JSON Response:")
                    logData(jsonString)
                    logData("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                }

                do {
                    // Try to decode the response
                    let decoder = JSONDecoder()

                    // Try different possible response formats
                    if let apiResponse = try? decoder.decode(APIResponse.self, from: data) {
                        let appList = apiResponse.applications ?? apiResponse.data ?? []
                        logInfo("✅ Decoded as APIResponse with \(appList.count) apps")
                        self?.parseApplicationList(appList)
                    } else if let appList = try? decoder.decode([ApplicationResponse].self, from: data) {
                        logInfo("✅ Decoded as array with \(appList.count) apps")
                        self?.parseApplicationList(appList)
                    } else {
                        throw NSError(domain: "DecodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode response"])
                    }
                } catch {
                    self?.errorMessage = "Failed to parse response: \(error.localizedDescription)"
                    logError("❌ Parsing error: \(error.localizedDescription)")
                    logError("📄 Error details: \(error)")
                    logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                }
            }
        }.resume()
    }

    private func parseApplicationList(_ appList: [ApplicationResponse]) {
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logInfo("Parsing Application List from server")
        logInfo("Received \(appList.count) applications from API")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        applications = appList.map { response in
            // Set default 10-minute limit if no limit is specified or limit is 0
            let dailyLimit = (response.dailyLimitTimeNumber ?? 10) > 0 ? (response.dailyLimitTimeNumber ?? 10) : 10
            let usedLimit = response.usedLimit ?? 0

            let app = ApplicationData(
                packageName: response.packageName,
                dailyLimitTimeNumber: dailyLimit,
                usedLimit: usedLimit,
                used: 0
            )

            return app
        }

        // Display applications in table format
        logInfo("")
        logSuccess("📋 PARSED APPLICATIONS TABLE")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logInfo(String(format: "%-40s %-30s %-15s %-15s", "PACKAGE NAME", "DISPLAY NAME", "DAILY LIMIT", "USED LIMIT"))
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        for (index, response) in appList.enumerated() {
            let app = applications[index]
            let displayName = response.displayText ?? getAppNameFromBundleId(response.packageName)
            let dailyLimitStr = "\(app.dailyLimitTimeNumber) min"
            let usedLimitStr = app.usedLimit > 0 ? "\(app.usedLimit) min" : "0 min"

            logData(String(format: "%-40s %-30s %-15s %-15s",
                          app.packageName,
                          displayName.truncated(to: 28),
                          dailyLimitStr,
                          usedLimitStr))
        }
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logInfo("")

        // Add default YouTube Music entry if not present in the API response
        let youtubeMusicBundleId = "com.google.ios.youtubemusic"
        if !applications.contains(where: { $0.packageName == youtubeMusicBundleId }) {
            let youtubeMusicApp = ApplicationData(
                packageName: youtubeMusicBundleId,
                dailyLimitTimeNumber: 10,  // 10 minutes daily limit
                usedLimit: 0,
                used: 0
            )
            applications.append(youtubeMusicApp)
            logApp("Added default: YouTube Music")
            logTime("Daily Limit: 10 minutes")
        }

        logSuccess("Successfully loaded \(applications.count) applications")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Set up monitoring with thresholds for each application
        let appsToMonitor = applications.map { app in
            (bundleIdentifier: app.packageName, dailyLimitMinutes: app.dailyLimitTimeNumber)
        }

        AppUsageManager.shared.startMonitoringApplications(appsToMonitor)

        // Update used times from threshold events
        updateUsedTimesFromThresholdEvents()
    }

    func updateUsedTimesFromThresholdEvents() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.tabnova.enterprise"),
              let events = sharedDefaults.array(forKey: "thresholdEvents") as? [[String: Any]] else {
            logWarning("No threshold events found in shared storage")
            return
        }

        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logInfo("Processing Threshold Events")
        logInfo("Found \(events.count) threshold events")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Log raw events for debugging
        for (index, event) in events.enumerated() {
            let bundleId = event["bundleIdentifier"] as? String ?? "unknown"
            let appName = event["applicationName"] as? String ?? "unknown"
            let minutes = event["thresholdMinutes"] as? Int ?? 0
            logData("Event #\(index + 1): bundleId=\(bundleId), app=\(appName), threshold=\(minutes)min")
        }

        // Group events by bundle identifier and track new events
        var usedTimes: [String: Int] = [:]
        var newEventsToReport: [(String, Int)] = []

        for event in events {
            guard let bundleId = event["bundleIdentifier"] as? String,
                  let thresholdMinutes = event["thresholdMinutes"] as? Int,
                  let timestamp = event["timestamp"] as? TimeInterval else {
                logWarning("⚠️ Skipping invalid event: \(event)")
                continue
            }

            // Create unique event ID
            let eventId = "\(bundleId)_\(timestamp)_\(thresholdMinutes)"

            let appName = event["applicationName"] as? String ?? bundleId
            let date = Date(timeIntervalSince1970: timestamp)
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"

            logEvent("Threshold hit: \(appName) at \(formatter.string(from: date)) - \(thresholdMinutes) min")

            // Track cumulative usage from AppUsageTracker
            if let currentUsage = usageTracker.getUsageForToday(packageName: bundleId) {
                usedTimes[bundleId] = currentUsage.totalMinutes
            } else {
                usedTimes[bundleId, default: 0] += thresholdMinutes
            }

            // Check if this is a new event that needs to be reported
            if !processedEventIds.contains(eventId) {
                newEventsToReport.append((bundleId, thresholdMinutes))
                processedEventIds.insert(eventId)
                logInfo("🆕 New threshold event detected for \(appName)")
            }
        }

        // Report new events to server
        if !newEventsToReport.isEmpty {
            logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            logNetwork("📤 Sending \(newEventsToReport.count) usage report(s) to server")
            logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }

        for (packageName, thresholdMinutes) in newEventsToReport {
            logApp("📱 Reporting: \(packageName) - \(thresholdMinutes) min")
            usageReporter.sendUsageReport(packageName: packageName, thresholdMinutes: thresholdMinutes) { success in
                if success {
                    logSuccess("✅ Usage report sent for \(packageName)")
                } else {
                    logError("❌ Failed to send usage report for \(packageName)")
                }
            }
        }

        // Update applications with the used times
        var updatedCount = 0
        for (index, app) in applications.enumerated() {
            if let usedTime = usedTimes[app.packageName] {
                applications[index].used = usedTime
                logSuccess("Updated \(app.packageName): used = \(usedTime) min")
                updatedCount += 1
            }
        }

        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logSuccess("Updated \(updatedCount) apps from \(events.count) threshold events")
        if !newEventsToReport.isEmpty {
            logInfo("Reported \(newEventsToReport.count) new threshold events to server")
        }
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    // MARK: - Helper Methods

    private func getAppNameFromBundleId(_ bundleId: String) -> String {
        // Extract a readable name from bundle identifier
        // e.g., "com.google.ios.youtubemusic" -> "YouTube Music"
        if let lastComponent = bundleId.components(separatedBy: ".").last {
            return lastComponent.capitalized
        }
        return bundleId
    }
}

// MARK: - String Extension

extension String {
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length - trailing.count)) + trailing
        }
        return self
    }
}
