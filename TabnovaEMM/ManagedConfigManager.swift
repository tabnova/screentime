import Foundation
import Combine

class ManagedConfigManager: ObservableObject {
    static let shared = ManagedConfigManager()

    @Published var authorization: String = ""
    @Published var email: String = ""
    @Published var profileId: String = ""
    @Published var serialNumber: String = ""

    private let userDefaults = UserDefaults.standard

    private init() {
        loadManagedConfiguration()
        setupManagedConfigObserver()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func loadManagedConfiguration() {
        // In a real MDM scenario, this would read from managed configuration
        // For now, we'll check UserDefaults first, then try to read from MDM

        logInfo("Loading managed configuration...")

        // Set default values if not already configured
        let defaultAuth = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI2NjEzYmNmZDg2YjFjZjg4YWIyMjliODciLCJlbWFpbCI6InJhcmFqYW5AZ21haWwuY29tIiwiaWF0IjoxNzY2MzgyNDM2LCJleHAiOjE5NDYzODI0MzZ9.ZavOiP_xZkQchbBdXmPrOTvqUVjmRlSrGu3W381uLw0"
        let defaultEmail = "rarajan@gmail.com"
        let defaultProfileId = "693701d3956f592b7cc05fc4"
        let defaultSerialNumber = "DMQCV4CWMF3N"

        // Try to read from UserDefaults (for testing), use defaults if not set
        if let storedAuth = userDefaults.string(forKey: "Authorization"), !storedAuth.isEmpty {
            authorization = storedAuth
            logKey("Using stored Authorization token")
        } else {
            authorization = defaultAuth
            userDefaults.set(defaultAuth, forKey: "Authorization")
            logSuccess("Set default Authorization token")
        }

        if let storedEmail = userDefaults.string(forKey: "email"), !storedEmail.isEmpty {
            email = storedEmail
            logInfo("Using stored email: \(storedEmail)")
        } else {
            email = defaultEmail
            userDefaults.set(defaultEmail, forKey: "email")
            logSuccess("Set default email: \(defaultEmail)")
        }

        if let storedProfileId = userDefaults.string(forKey: "profileId"), !storedProfileId.isEmpty {
            profileId = storedProfileId
            logInfo("Using stored profileId: \(storedProfileId)")
        } else {
            profileId = defaultProfileId
            userDefaults.set(defaultProfileId, forKey: "profileId")
            logSuccess("Set default profileId: \(defaultProfileId)")
        }

        if let storedSerialNumber = userDefaults.string(forKey: "serialNumber"), !storedSerialNumber.isEmpty {
            serialNumber = storedSerialNumber
            logInfo("Using stored serialNumber: \(storedSerialNumber)")
        } else {
            serialNumber = defaultSerialNumber
            userDefaults.set(defaultSerialNumber, forKey: "serialNumber")
            logSuccess("Set default serialNumber: \(defaultSerialNumber)")
        }

        // Try to read from managed configuration (MDM) - this will override defaults
        if let managedConfig = UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed") {
            logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            logSuccess("📱 RECEIVED MANAGED CONFIGURATION FROM MDM")
            logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            logData("Managed Config Keys: \(managedConfig.keys.joined(separator: ", "))")

            if let auth = managedConfig["Authorization"] as? String {
                authorization = auth
                userDefaults.set(auth, forKey: "Authorization")
                logSuccess("✅ Received Authorization from MDM")
                logKey("   Token: ***\(String(auth.suffix(20)))")
            }
            if let emailValue = managedConfig["email"] as? String {
                email = emailValue
                userDefaults.set(emailValue, forKey: "email")
                logSuccess("✅ Received email from MDM: \(emailValue)")
            }
            if let profileIdValue = managedConfig["profileId"] as? String {
                profileId = profileIdValue
                userDefaults.set(profileIdValue, forKey: "profileId")
                logSuccess("✅ Received profileId from MDM: \(profileIdValue)")
            }
            if let serialNumberValue = managedConfig["serialNumber"] as? String {
                serialNumber = serialNumberValue
                userDefaults.set(serialNumberValue, forKey: "serialNumber")
                logSuccess("✅ Received serialNumber from MDM: \(serialNumberValue)")
            }
            logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        } else {
            logInfo("ℹ️ No managed configuration found from MDM (using defaults)")
        }

        // Print current values
        printConfiguration()
    }

    func updateConfiguration(authorization: String? = nil, email: String? = nil, profileId: String? = nil, serialNumber: String? = nil) {
        if let auth = authorization {
            self.authorization = auth
            userDefaults.set(auth, forKey: "Authorization")
            logSuccess("Updated Authorization")
        }
        if let emailValue = email {
            self.email = emailValue
            userDefaults.set(emailValue, forKey: "email")
            logSuccess("Updated email: \(emailValue)")
        }
        if let profileIdValue = profileId {
            self.profileId = profileIdValue
            userDefaults.set(profileIdValue, forKey: "profileId")
            logSuccess("Updated profileId: \(profileIdValue)")
        }
        if let serialNumberValue = serialNumber {
            self.serialNumber = serialNumberValue
            userDefaults.set(serialNumberValue, forKey: "serialNumber")
            logSuccess("Updated serialNumber: \(serialNumberValue)")
        }

        printConfiguration()
    }

    func printConfiguration() {
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logInfo("Managed Configuration:")
        logKey("Authorization: \(authorization.isEmpty ? "Not set" : "***" + String(authorization.suffix(20)))")
        logInfo("Email: \(email.isEmpty ? "Not set" : email)")
        logInfo("Profile ID: \(profileId.isEmpty ? "Not set" : profileId)")
        logInfo("Serial Number: \(serialNumber.isEmpty ? "Not set" : serialNumber)")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    // MARK: - MDM Config Observer
    private func setupManagedConfigObserver() {
        // Observe changes to managed configuration
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(managedConfigDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )

        logInfo("📡 MDM config observer set up - will auto-fetch app list on config changes")
    }

    @objc private func managedConfigDidChange() {
        // Check if managed configuration actually changed
        if let managedConfig = UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed") {
            var configChanged = false

            // Check for authorization changes
            if let newAuth = managedConfig["Authorization"] as? String, newAuth != authorization {
                authorization = newAuth
                userDefaults.set(newAuth, forKey: "Authorization")
                configChanged = true
                logSuccess("✅ MDM Authorization updated")
            }

            // Check for email changes
            if let newEmail = managedConfig["email"] as? String, newEmail != email {
                email = newEmail
                userDefaults.set(newEmail, forKey: "email")
                configChanged = true
                logSuccess("✅ MDM email updated: \(newEmail)")
            }

            // Check for profileId changes
            if let newProfileId = managedConfig["profileId"] as? String, newProfileId != profileId {
                profileId = newProfileId
                userDefaults.set(newProfileId, forKey: "profileId")
                configChanged = true
                logSuccess("✅ MDM profileId updated: \(newProfileId)")
            }

            // Check for serialNumber changes
            if let newSerialNumber = managedConfig["serialNumber"] as? String, newSerialNumber != serialNumber {
                serialNumber = newSerialNumber
                userDefaults.set(newSerialNumber, forKey: "serialNumber")
                configChanged = true
                logSuccess("✅ MDM serialNumber updated: \(newSerialNumber)")
            }

            // If config changed, fetch updated application list
            if configChanged {
                logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                logSuccess("🔄 MDM CONFIG CHANGED - Auto-fetching app list")
                logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

                // Fetch updated application list from server
                ApplicationAPIService.shared.fetchApplicationList()
            }
        }
    }
}
