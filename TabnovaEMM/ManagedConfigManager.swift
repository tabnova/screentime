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

        // Try to read from UserDefaults (for testing)
        if let storedAuth = userDefaults.string(forKey: "Authorization") {
            authorization = storedAuth
        }
        if let storedEmail = userDefaults.string(forKey: "email") {
            email = storedEmail
        }
        if let storedProfileId = userDefaults.string(forKey: "profileId") {
            profileId = storedProfileId
        }
        if let storedSerialNumber = userDefaults.string(forKey: "serialNumber") {
            serialNumber = storedSerialNumber
        }

        // Try to read from managed configuration (MDM)
        if let managedConfig = UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed") {
            if let auth = managedConfig["Authorization"] as? String {
                authorization = auth
                userDefaults.set(auth, forKey: "Authorization")
                print("✅ Received Authorization: \(auth)")
            }
            if let emailValue = managedConfig["email"] as? String {
                email = emailValue
                userDefaults.set(emailValue, forKey: "email")
                print("✅ Received email: \(emailValue)")
            }
            if let profileIdValue = managedConfig["profileId"] as? String {
                profileId = profileIdValue
                userDefaults.set(profileIdValue, forKey: "profileId")
                print("✅ Received profileId: \(profileIdValue)")
            }
            if let serialNumberValue = managedConfig["serialNumber"] as? String {
                serialNumber = serialNumberValue
                userDefaults.set(serialNumberValue, forKey: "serialNumber")
                print("✅ Received serialNumber: \(serialNumberValue)")
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
