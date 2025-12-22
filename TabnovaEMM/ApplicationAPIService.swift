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
            print("❌ Error: Profile ID is not set")
            return
        }

        guard !configManager.authorization.isEmpty else {
            errorMessage = "Authorization token is not set in managed configuration"
            print("❌ Error: Authorization token is not set")
            return
        }

        isLoading = true
        errorMessage = nil

        let urlString = "https://b2b.novaemm.com:4500/api/v1/admin/device-profile/application/list?profile_id=\(configManager.profileId)&type=GET"

        print("🌐 Fetching application list from: \(urlString)")
        print("🔑 Authorization: \(configManager.authorization)")

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            print("❌ Error: Invalid URL")
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
                    print("❌ Network error: \(error.localizedDescription)")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status Code: \(httpResponse.statusCode)")

                    guard (200...299).contains(httpResponse.statusCode) else {
                        self?.errorMessage = "Server error: HTTP \(httpResponse.statusCode)"
                        print("❌ Server error: HTTP \(httpResponse.statusCode)")
                        return
                    }
                }

                guard let data = data else {
                    self?.errorMessage = "No data received"
                    print("❌ No data received")
                    return
                }

                // Print raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📦 Raw JSON Response:")
                    print(jsonString)
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
                    print("❌ Parsing error: \(error)")
                }
            }
        }.resume()
    }

    private func parseApplicationList(_ appList: [ApplicationResponse]) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📋 Parsed Application List:")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        applications = appList.map { response in
            let app = ApplicationData(
                packageName: response.packageName,
                dailyLimitTimeNumber: response.dailyLimitTimeNumber,
                usedLimit: response.usedLimit,
                used: 0
            )

            print("📱 Package: \(app.packageName)")
            print("   ⏱️  Daily Limit: \(app.dailyLimitTimeNumber) minutes")
            print("   📊 Used Limit: \(app.usedLimit)")
            print("   ✅ Used: \(app.used) minutes")
            print("   ───────────────────────────────")

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
            print("📱 Added default: YouTube Music")
            print("   ⏱️  Daily Limit: 10 minutes")
            print("   📊 Used Limit: 0")
            print("   ✅ Used: 0 minutes")
            print("   ───────────────────────────────")
        }

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✅ Successfully loaded \(applications.count) applications")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Set up monitoring with thresholds for each application
        let appsToMonitor = applications.map { app in
            (bundleIdentifier: app.packageName, dailyLimitMinutes: app.dailyLimitTimeNumber)
        }

        AppUsageManager.shared.startMonitoringApplications(appsToMonitor)
    }
}
