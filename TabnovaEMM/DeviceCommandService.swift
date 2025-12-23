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
            logError("Profile ID is not set for YES command")
            completion?(false)
            return
        }

        guard !configManager.authorization.isEmpty else {
            errorMessage = "Authorization token is not set in managed configuration"
            logError("Authorization token is not set for YES command")
            completion?(false)
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        let urlString = "https://b2b.novaemm.com:4500/api/v1/admin/device-profile/command?profile_id=\(configManager.profileId)&type=YES"

        logNetwork("Sending YES command to server")
        logInfo("Profile ID: \(configManager.profileId)")

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            logError("Invalid URL for YES command")
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

        logData("Request body: \(deviceInfo)")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: deviceInfo, options: [])
        } catch {
            errorMessage = "Failed to create request body: \(error.localizedDescription)"
            isLoading = false
            logError("Error creating request body: \(error.localizedDescription)")
            completion?(false)
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    logError("Network error sending YES command: \(error.localizedDescription)")
                    completion?(false)
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    logNetwork("YES command HTTP Status: \(httpResponse.statusCode)")

                    guard (200...299).contains(httpResponse.statusCode) else {
                        self?.errorMessage = "Server error: HTTP \(httpResponse.statusCode)"
                        logError("Server error for YES command: HTTP \(httpResponse.statusCode)")
                        completion?(false)
                        return
                    }
                }

                guard let data = data else {
                    self?.errorMessage = "No data received"
                    logError("No data received from YES command")
                    completion?(false)
                    return
                }

                // Log raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    logData("YES command response: \(jsonString)")
                }

                do {
                    let decoder = JSONDecoder()
                    let commandResponse = try decoder.decode(CommandResponse.self, from: data)

                    if commandResponse.success {
                        self?.successMessage = commandResponse.message ?? "YES command sent successfully"
                        logSuccess("YES command sent successfully")
                        if let message = commandResponse.message {
                            logInfo("Response: \(message)")
                        }
                        completion?(true)
                    } else {
                        self?.errorMessage = commandResponse.message ?? "Command failed"
                        logError("YES command failed: \(commandResponse.message ?? "Unknown error")")
                        completion?(false)
                    }
                } catch {
                    // If the response doesn't match our expected format, consider it a success if we got a 2xx status
                    self?.successMessage = "YES command sent successfully"
                    logSuccess("YES command sent (assumed success based on HTTP status)")
                    completion?(true)
                }
            }
        }.resume()
    }
}
