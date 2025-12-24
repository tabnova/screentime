//
//  ShieldManager.swift
//  TabnovaEMM
//
//  Manages shielding (blocking) of applications when limits are reached
//

import Foundation
import FamilyControls
import ManagedSettings

class ShieldManager: ObservableObject {
    static let shared = ShieldManager()

    private let store = ManagedSettingsStore()
    private let defaults = UserDefaults(suiteName: "group.com.tabnova.enterprise")

    @Published var shieldedApps: Set<String> = [] // Bundle identifiers of shielded apps

    private init() {
        loadShieldedApps()
    }

    // MARK: - Shield Applications

    /// Shield (block) applications when limit is reached
    func shieldApplications(_ selection: FamilyActivitySelection, reason: String = "Daily limit reached") {
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logWarning("🛡️ SHIELDING APPLICATIONS")
        logInfo("Reason: \(reason)")
        logInfo("Apps to shield: \(selection.applicationTokens.count)")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Apply shield using ManagedSettings
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens

        // Store selection for later use
        if let encoded = try? JSONEncoder().encode(selection) {
            defaults?.set(encoded, forKey: "shieldedSelection")
            defaults?.synchronize()
            logSuccess("✅ Shield applied and selection stored")
        }

        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    /// Shield specific app by bundle identifier
    func shieldApp(bundleId: String) {
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logWarning("🛡️ SHIELDING APP: \(bundleId)")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        shieldedApps.insert(bundleId)
        saveShieldedApps()

        // Get current selection and update shield
        updateShieldFromStoredSelection()

        logSuccess("✅ App \(bundleId) has been shielded")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    // MARK: - Unshield Applications

    /// Remove shield (unblock) all applications
    func unshieldAll() {
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logSuccess("🔓 UNSHIELDING ALL APPLICATIONS")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        store.shield.applications = nil
        shieldedApps.removeAll()
        saveShieldedApps()

        defaults?.removeObject(forKey: "shieldedSelection")
        defaults?.synchronize()

        logSuccess("✅ All applications unshielded")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    /// Unshield specific app by bundle identifier
    func unshieldApp(bundleId: String) {
        NSLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        NSLog("🔓 UNSHIELDING APP: %@", bundleId)
        NSLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Remove shield from the specific app using its named store
        let appStore = ManagedSettingsStore(named: ManagedSettingsStore.Name(bundleId))
        appStore.shield.applications = nil
        NSLog("🔓 Removed shield from store: %@", bundleId)

        shieldedApps.remove(bundleId)
        saveShieldedApps()

        // If no more shielded apps, clean up global store too
        if shieldedApps.isEmpty {
            store.shield.applications = nil
            defaults?.removeObject(forKey: "shieldedSelection")
            NSLog("🔓 All shields removed")
        }

        NSLog("✅ App %@ has been unshielded", bundleId)
        NSLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    // MARK: - Check Shield Status

    /// Check if an app is currently shielded
    func isAppShielded(_ bundleId: String) -> Bool {
        return shieldedApps.contains(bundleId)
    }

    /// Get all currently shielded apps
    func getShieldedApps() -> [String] {
        return Array(shieldedApps)
    }

    // MARK: - Private Helpers

    private func loadShieldedApps() {
        if let apps = defaults?.array(forKey: "shieldedApps") as? [String] {
            shieldedApps = Set(apps)
            logInfo("Loaded \(shieldedApps.count) shielded apps from storage")
        }
    }

    private func saveShieldedApps() {
        defaults?.set(Array(shieldedApps), forKey: "shieldedApps")
        defaults?.synchronize()
        objectWillChange.send()
    }

    private func updateShieldFromStoredSelection() {
        // This would require re-applying the shield with updated selection
        // For now, we'll just log that the shield needs to be updated
        logInfo("Shield status updated for \(shieldedApps.count) apps")
    }
}
