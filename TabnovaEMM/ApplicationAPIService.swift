import Foundation
import Combine

struct APIResponse: Codable {
    let applications: [ApplicationResponse]?
    let data: [ApplicationResponse]?
}

struct ApplicationResponse: Codable {
    let packageName: String
    let dailyLimitTimeNumber: Int
    let usedLimit: Int

    enum CodingKeys: String, CodingKey {
        case packageName = "package_name"
        case dailyLimitTimeNumber = "dailyLimitTimeNumber"
        case usedLimit
    }
}

class ApplicationAPIService: ObservableObject {
    @Published var applications: [ApplicationData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let configManager = ManagedConfigManager.shared

    func fetchApplicationList() {
        guard !configManager.profileId.isEmpty else {
            errorMessage = "Profile ID is not set in managed configuration"
            logError("Profile ID is not set")
            return
        }

        guard !configManager.authorization.isEmpty else {
            errorMessage = "Authorization token is not set in managed configuration"
            logError("Authorization token is not set")
            return
        }

        isLoading = true
        errorMessage = nil

        let urlString = "https://b2b.novaemm.com:4500/api/v1/admin/device-profile/application/list?profile_id=\(configManager.profileId)&type=GET"

        logNetwork("Fetching application list from API")
        logKey("Using profile ID: \(configManager.profileId)")

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            logError("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(configManager.authorization, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    logError("Network error: \(error.localizedDescription)")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    logNetwork("HTTP Status Code: \(httpResponse.statusCode)")

                    guard (200...299).contains(httpResponse.statusCode) else {
                        self?.errorMessage = "Server error: HTTP \(httpResponse.statusCode)"
                        logError("Server error: HTTP \(httpResponse.statusCode)")
                        return
                    }
                }

                guard let data = data else {
                    self?.errorMessage = "No data received"
                    logError("No data received")
                    return
                }

                // Log raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    logData("Raw JSON Response: \(jsonString)")
                }

                do {
                    // Try to decode the response
                    let decoder = JSONDecoder()

                    // Try different possible response formats
                    if let apiResponse = try? decoder.decode(APIResponse.self, from: data) {
                        let appList = apiResponse.applications ?? apiResponse.data ?? []
                        self?.parseApplicationList(appList)
                    } else if let appList = try? decoder.decode([ApplicationResponse].self, from: data) {
                        self?.parseApplicationList(appList)
                    } else {
                        throw NSError(domain: "DecodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode response"])
                    }
                } catch {
                    self?.errorMessage = "Failed to parse response: \(error.localizedDescription)"
                    logError("Parsing error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    private func parseApplicationList(_ appList: [ApplicationResponse]) {
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logInfo("Parsing Application List from server")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        applications = appList.map { response in
            // Set default 10-minute limit if no limit is specified or limit is 0
            let dailyLimit = response.dailyLimitTimeNumber > 0 ? response.dailyLimitTimeNumber : 10

            let app = ApplicationData(
                packageName: response.packageName,
                dailyLimitTimeNumber: dailyLimit,
                usedLimit: response.usedLimit,
                used: 0
            )

            logApp("Package: \(app.packageName)")
            logTime("Daily Limit: \(app.dailyLimitTimeNumber) minutes")
            logData("Used Limit: \(app.usedLimit)")
            logData("Current Used: \(app.used) minutes")

            return app
        }

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

        // Group events by bundle identifier and sum up the threshold minutes
        var usedTimes: [String: Int] = [:]

        for event in events {
            guard let bundleId = event["bundleIdentifier"] as? String,
                  let thresholdMinutes = event["thresholdMinutes"] as? Int,
                  let timestamp = event["timestamp"] as? TimeInterval else {
                continue
            }

            let appName = event["applicationName"] as? String ?? bundleId
            let date = Date(timeIntervalSince1970: timestamp)
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"

            logEvent("Threshold hit: \(appName) at \(formatter.string(from: date)) - \(thresholdMinutes) min")

            usedTimes[bundleId, default: 0] = thresholdMinutes
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
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
}
