import Foundation
import Combine

struct APIResponse: Codable {
    let applications: [ApplicationResponse]?
    let data: [ApplicationResponse]?
}

struct ApplicationResponse: Codable {
    let packageName: String
    let dailyLimitTimeNumber: String?  // API returns as string (e.g., "90", "45") or null
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
        // Log at the very start to confirm function is called
        print("🚨🚨🚨 fetchApplicationList() CALLED 🚨🚨🚨")

        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logNetwork("📡 FETCH APPLICATION LIST BUTTON PRESSED")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logInfo("🔍 Starting fetch application list process...")
        logInfo("📋 Current app count: \(applications.count)")

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

        let urlString = "https://b2b.novaemm.com:4500/api/v1/admin/device-profile/application/list?profile_id=\(configManager.profileId)"

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
            // Add crash protection - log before entering main queue
            NSLog("🔵 URLSession callback received")

            DispatchQueue.main.async {
                // Add crash protection for main queue operations
                NSLog("🔵 Entered main queue")

                defer {
                    NSLog("🔵 Exiting main queue")
                }

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
                    // Only log first 500 characters to avoid crash from huge JSON
                    let preview = jsonString.prefix(500)
                    logData("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    logData("📄 Raw JSON Response (first 500 chars):")
                    logData(String(preview))
                    if jsonString.count > 500 {
                        logData("... (\(jsonString.count - 500) more characters)")
                    }
                    logData("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                }

                NSLog("🔵 About to decode JSON")

                do {
                    // Try to decode the response
                    let decoder = JSONDecoder()

                    NSLog("🔵 Attempting APIResponse decode")
                    // Try different possible response formats
                    if let apiResponse = try? decoder.decode(APIResponse.self, from: data) {
                        NSLog("🔵 Successfully decoded as APIResponse")
                        let appList = apiResponse.applications ?? apiResponse.data ?? []
                        logInfo("✅ Decoded as APIResponse with \(appList.count) apps")

                        NSLog("🔵 About to call parseApplicationList")
                        self?.parseApplicationList(appList)
                        NSLog("🔵 Finished parseApplicationList")
                    } else {
                        NSLog("🔵 Attempting array decode")
                        if let appList = try? decoder.decode([ApplicationResponse].self, from: data) {
                            NSLog("🔵 Successfully decoded as array")
                            logInfo("✅ Decoded as array with \(appList.count) apps")

                            NSLog("🔵 About to call parseApplicationList")
                            self?.parseApplicationList(appList)
                            NSLog("🔵 Finished parseApplicationList")
                        } else {
                            NSLog("🔵 Both decode attempts failed")
                            throw NSError(domain: "DecodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode response"])
                        }
                    }
                } catch {
                    NSLog("🔵 Caught error: \(error)")
                    self?.errorMessage = "Failed to parse response: \(error.localizedDescription)"
                    logError("❌ Parsing error: \(error.localizedDescription)")
                    logError("📄 Error details: \(error)")
                    logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                }
            }
        }.resume()
    }

    private func parseApplicationList(_ appList: [ApplicationResponse]) {
        NSLog("🔵 parseApplicationList called with \(appList.count) apps")

        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logInfo("Parsing Application List from server")
        logInfo("Received \(appList.count) applications from API")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        NSLog("🔵 About to map applications")

        applications = appList.map { response in
            NSLog("🔵 Mapping app: \(response.packageName)")

            // Parse dailyLimitTimeNumber from string to int
            // API returns it as string (e.g., "90", "45") or null
            var dailyLimit = 10  // Default 10 minutes
            if let limitString = response.dailyLimitTimeNumber {
                NSLog("🔵 Limit string: '\(limitString)'")
                if let parsedLimit = Int(limitString), parsedLimit > 0 {
                    dailyLimit = parsedLimit
                    NSLog("🔵 Parsed limit: \(dailyLimit)")
                } else {
                    NSLog("🔵 Could not parse limit, using default 10")
                }
            } else {
                NSLog("🔵 No limit string, using default 10")
            }

            let usedLimit = response.usedLimit ?? 0

            let app = ApplicationData(
                packageName: response.packageName,
                dailyLimitTimeNumber: dailyLimit,
                usedLimit: usedLimit,
                used: 0
            )

            NSLog("🔵 Created app: \(app.packageName) with limit \(app.dailyLimitTimeNumber)")

            return app
        }

        NSLog("🔵 Finished mapping \(applications.count) applications")

        NSLog("🔵 About to log table header")
        // Display applications in table format - SIMPLIFIED to avoid crash
        logInfo("")
        NSLog("🔵 Logged empty line")

        logSuccess("📋 PARSED APPLICATIONS TABLE")
        NSLog("🔵 Logged table title")

        // Simplified separator to avoid potential crash
        let separator = String(repeating: "=", count: 80)
        logInfo(separator)
        NSLog("🔵 Logged separator")

        // Use Swift string padding for column headers (avoid C-style format crash)
        let header = "\("PACKAGE NAME".padding(toLength: 40, withPad: " ", startingAt: 0)) \("DISPLAY NAME".padding(toLength: 30, withPad: " ", startingAt: 0)) \("DAILY LIMIT".padding(toLength: 15, withPad: " ", startingAt: 0)) \("USED LIMIT".padding(toLength: 15, withPad: " ", startingAt: 0))"
        logInfo(header)
        NSLog("🔵 Logged column headers")

        logInfo(separator)
        NSLog("🔵 Logged separator 2")

        NSLog("🔵 About to enumerate appList")
        for (index, response) in appList.enumerated() {
            NSLog("🔵 Processing app index \(index)")
            let app = applications[index]

            NSLog("🔵 Getting display name for \(response.packageName)")
            let displayName = response.displayText ?? getAppNameFromBundleId(response.packageName)

            NSLog("🔵 Creating limit strings")
            let dailyLimitStr = "\(app.dailyLimitTimeNumber) min"
            let usedLimitStr = app.usedLimit > 0 ? "\(app.usedLimit) min" : "0 min"

            NSLog("🔵 About to truncate displayName: \(displayName)")
            let truncatedName = displayName.count > 28 ? String(displayName.prefix(26)) + ".." : displayName

            NSLog("🔵 About to format string")
            // Use Swift string padding instead of C-style format (%-40s causes crash)
            let packagePadded = app.packageName.padding(toLength: 40, withPad: " ", startingAt: 0)
            let namePadded = truncatedName.padding(toLength: 30, withPad: " ", startingAt: 0)
            let limitPadded = dailyLimitStr.padding(toLength: 15, withPad: " ", startingAt: 0)
            let usedPadded = usedLimitStr.padding(toLength: 15, withPad: " ", startingAt: 0)
            let formattedLine = "\(packagePadded) \(namePadded) \(limitPadded) \(usedPadded)"

            NSLog("🔵 About to log formatted line")
            logData(formattedLine)
            NSLog("🔵 Logged app \(index + 1)/\(appList.count)")
        }

        NSLog("🔵 Finished enumeration, logging final separator")
        logInfo(separator)
        logInfo("")

        NSLog("🔵 About to log application summary")
        // Log summary for each application
        logSuccess("📱 APPLICATION SUMMARY:")
        for (index, app) in applications.enumerated() {
            NSLog("🔵 Logging summary for app \(index + 1)")
            logApp("  • \(app.packageName)")
            logTime("    Daily Limit: \(app.dailyLimitTimeNumber) minutes")
            if app.usedLimit > 0 {
                logData("    Used Limit: \(app.usedLimit) minutes")
            }
        }
        NSLog("🔵 Finished summary, logging final separator")
        logInfo(separator)

        // No test data - only use applications from server
        logSuccess("Successfully loaded \(applications.count) applications")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Check for limit changes and update monitored apps
        updateMonitoredAppsWithNewLimits(applications: applications)

        logInfo("💡 To monitor apps: Use 'Start Monitoring' button for each app")
        logInfo("   This will open FamilyActivityPicker to select the app")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Update used times from threshold events
        updateUsedTimesFromThresholdEvents()
    }

    // MARK: - Update Monitored Apps with New Limits
    private func updateMonitoredAppsWithNewLimits(applications: [ApplicationData]) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.tabnova.enterprise"),
              let tokenMappings = sharedDefaults.dictionary(forKey: "appTokenMappings") as? [String: String] else {
            NSLog("ℹ️ No monitored apps to update")
            return
        }

        NSLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        NSLog("🔄 Checking for limit changes in monitored apps")
        NSLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        for (bundleId, _) in tokenMappings {
            // Find this app in the new application list
            guard let newAppData = applications.first(where: { $0.packageName == bundleId }) else {
                NSLog("⚠️ %@ not in server list - keeping current monitoring", bundleId)
                continue
            }

            // Get current limit from shared defaults
            let currentLimit = sharedDefaults.integer(forKey: "monitoredLimit.\(bundleId)")
            let newLimit = newAppData.dailyLimitTimeNumber

            if currentLimit != newLimit {
                NSLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                NSLog("🔄 LIMIT CHANGED for %@", bundleId)
                NSLog("   Old Limit: %d minutes", currentLimit)
                NSLog("   New Limit: %d minutes", newLimit)

                // Check if app is currently shielded
                let shieldManager = ShieldManager.shared
                let wasShielded = shieldManager.isAppShielded(bundleId)

                if wasShielded {
                    NSLog("   🔓 App was shielded - removing shield")
                    shieldManager.unshieldApp(bundleId: bundleId)
                }

                // Restart monitoring with new limit
                NSLog("   🔄 Restarting monitoring with new limit")

                // Get the stored token
                if let selectionData = sharedDefaults.data(forKey: "monitoredSelection.\(bundleId)"),
                   let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selectionData),
                   let token = selection.applicationTokens.first {

                    // Stop old monitoring
                    AppUsageManager.shared.stopMonitoringApp(bundleId: bundleId)

                    // Start new monitoring with updated limit
                    AppUsageManager.shared.startMonitoringApp(
                        bundleId: bundleId,
                        dailyLimitMinutes: newLimit,
                        token: token,
                        displayName: bundleId
                    )

                    NSLog("   ✅ Updated successfully - new limit: %d min", newLimit)
                } else {
                    NSLog("   ⚠️ Could not reload token - manual restart needed")
                }

                NSLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            } else {
                NSLog("✓ %@ limit unchanged (%d min)", bundleId, currentLimit)
            }
        }

        NSLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
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
