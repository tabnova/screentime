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
    }

    func loadManagedConfiguration() {
        // In a real MDM scenario, this would read from managed configuration
        // For now, we'll check UserDefaults first, then try to read from MDM

        // Set default values if not already configured
        let defaultAuth = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI2NjEzYmNmZDg2YjFjZjg4YWIyMjliODciLCJlbWFpbCI6InJhcmFqYW5AZ21haWwuY29tIiwiaWF0IjoxNzY2MzgyNDM2LCJleHAiOjE5NDYzODI0MzZ9.ZavOiP_xZkQchbBdXmPrOTvqUVjmRlSrGu3W381uLw0"
        let defaultEmail = "rarajan@gmail.com"
        let defaultProfileId = "693701d3956f592b7cc05fc4"
        let defaultSerialNumber = "DMQCV4CWMF3N"

        // Try to read from UserDefaults (for testing), use defaults if not set
        if let storedAuth = userDefaults.string(forKey: "Authorization"), !storedAuth.isEmpty {
            authorization = storedAuth
        } else {
            authorization = defaultAuth
            userDefaults.set(defaultAuth, forKey: "Authorization")
            print("✅ Set default Authorization")
        }

        if let storedEmail = userDefaults.string(forKey: "email"), !storedEmail.isEmpty {
            email = storedEmail
        } else {
            email = defaultEmail
            userDefaults.set(defaultEmail, forKey: "email")
            print("✅ Set default email: \(defaultEmail)")
        }

        if let storedProfileId = userDefaults.string(forKey: "profileId"), !storedProfileId.isEmpty {
            profileId = storedProfileId
        } else {
            profileId = defaultProfileId
            userDefaults.set(defaultProfileId, forKey: "profileId")
            print("✅ Set default profileId: \(defaultProfileId)")
        }

        if let storedSerialNumber = userDefaults.string(forKey: "serialNumber"), !storedSerialNumber.isEmpty {
            serialNumber = storedSerialNumber
        } else {
            serialNumber = defaultSerialNumber
            userDefaults.set(defaultSerialNumber, forKey: "serialNumber")
            print("✅ Set default serialNumber: \(defaultSerialNumber)")
        }

        // Try to read from managed configuration (MDM) - this will override defaults
        if let managedConfig = UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed") {
            if let auth = managedConfig["Authorization"] as? String {
                authorization = auth
                userDefaults.set(auth, forKey: "Authorization")
                print("✅ Received Authorization from MDM")
            }
            if let emailValue = managedConfig["email"] as? String {
                email = emailValue
                userDefaults.set(emailValue, forKey: "email")
                print("✅ Received email from MDM: \(emailValue)")
            }
            if let profileIdValue = managedConfig["profileId"] as? String {
                profileId = profileIdValue
                userDefaults.set(profileIdValue, forKey: "profileId")
                print("✅ Received profileId from MDM: \(profileIdValue)")
            }
            if let serialNumberValue = managedConfig["serialNumber"] as? String {
                serialNumber = serialNumberValue
                userDefaults.set(serialNumberValue, forKey: "serialNumber")
                print("✅ Received serialNumber from MDM: \(serialNumberValue)")
            }
        }

        // Print current values
        printConfiguration()
    }

    func updateConfiguration(authorization: String? = nil, email: String? = nil, profileId: String? = nil, serialNumber: String? = nil) {
        if let auth = authorization {
            self.authorization = auth
            userDefaults.set(auth, forKey: "Authorization")
            print("✅ Updated Authorization: \(auth)")
        }
        if let emailValue = email {
            self.email = emailValue
            userDefaults.set(emailValue, forKey: "email")
            print("✅ Updated email: \(emailValue)")
        }
        if let profileIdValue = profileId {
            self.profileId = profileIdValue
            userDefaults.set(profileIdValue, forKey: "profileId")
            print("✅ Updated profileId: \(profileIdValue)")
        }
        if let serialNumberValue = serialNumber {
            self.serialNumber = serialNumberValue
            userDefaults.set(serialNumberValue, forKey: "serialNumber")
            print("✅ Updated serialNumber: \(serialNumberValue)")
        }

        printConfiguration()
    }

    func printConfiguration() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📋 Managed Configuration:")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Authorization: \(authorization.isEmpty ? "Not set" : authorization)")
        print("Email: \(email.isEmpty ? "Not set" : email)")
        print("Profile ID: \(profileId.isEmpty ? "Not set" : profileId)")
        print("Serial Number: \(serialNumber.isEmpty ? "Not set" : serialNumber)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
}
