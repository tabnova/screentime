import Foundation
import Combine

struct CommandResponse: Codable {
    let success: Bool
    let message: String?
}

class DeviceCommandService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let configManager = ManagedConfigManager.shared

    func sendYesCommand(completion: ((Bool) -> Void)? = nil) {
        guard !configManager.profileId.isEmpty else {
            errorMessage = "Profile ID is not set in managed configuration"
            print("❌ Error: Profile ID is not set")
            completion?(false)
            return
        }

        guard !configManager.authorization.isEmpty else {
            errorMessage = "Authorization token is not set in managed configuration"
            print("❌ Error: Authorization token is not set")
            completion?(false)
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        let urlString = "https://b2b.novaemm.com:4500/api/v1/admin/device-profile/command?profile_id=\(configManager.profileId)&type=YES"

        print("🌐 Sending YES command to: \(urlString)")
        print("🔑 Authorization: \(configManager.authorization)")

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            print("❌ Error: Invalid URL")
            completion?(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(configManager.authorization, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create request body with device information
        let deviceInfo: [String: Any] = [
            "command": "YES",
            "deviceName": UIDevice.current.name,
            "deviceModel": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion,
            "serialNumber": configManager.serialNumber,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: deviceInfo, options: [])
        } catch {
            errorMessage = "Failed to create request body: \(error.localizedDescription)"
            isLoading = false
            print("❌ Error creating request body: \(error)")
            completion?(false)
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    print("❌ Network error: \(error.localizedDescription)")
                    completion?(false)
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status Code: \(httpResponse.statusCode)")

                    guard (200...299).contains(httpResponse.statusCode) else {
                        self?.errorMessage = "Server error: HTTP \(httpResponse.statusCode)"
                        print("❌ Server error: HTTP \(httpResponse.statusCode)")
                        completion?(false)
                        return
                    }
                }

                guard let data = data else {
                    self?.errorMessage = "No data received"
                    print("❌ No data received")
                    completion?(false)
                    return
                }

                // Print raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📦 Raw JSON Response:")
                    print(jsonString)
                }

                do {
                    let decoder = JSONDecoder()
                    let commandResponse = try decoder.decode(CommandResponse.self, from: data)

                    if commandResponse.success {
                        self?.successMessage = commandResponse.message ?? "YES command sent successfully"
                        print("✅ YES command sent successfully")
                        print("✅ Response: \(commandResponse.message ?? "")")
                        completion?(true)
                    } else {
                        self?.errorMessage = commandResponse.message ?? "Command failed"
                        print("❌ Command failed: \(commandResponse.message ?? "")")
                        completion?(false)
                    }
                } catch {
                    // If the response doesn't match our expected format, consider it a success if we got a 2xx status
                    self?.successMessage = "YES command sent successfully"
                    print("✅ YES command sent (assumed success based on HTTP status)")
                    completion?(true)
                }
            }
        }.resume()
    }
}
