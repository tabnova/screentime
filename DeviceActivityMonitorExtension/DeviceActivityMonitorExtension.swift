//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitorExtension
//
//  TabnovaEMM - Device Activity Monitor Extension
//  This extension handles Screen Time monitoring events
//

import DeviceActivity
import Foundation
import UserNotifications
import ManagedSettings
import FamilyControls

/// Device Activity Monitor Extension
/// This extension is required by the FamilyControls framework to receive
/// callbacks when device activity events occur (interval start/end, thresholds)
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        let activityName = String(describing: activity)
        logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logMessage("✅ Monitoring interval started")
        logMessage("   Activity: \(activityName)")
        logMessage("   Time: \(getCurrentTimestamp())")
        logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        let activityName = String(describing: activity)
        logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logMessage("⏹️ Monitoring interval ended")
        logMessage("   Activity: \(activityName)")
        logMessage("   Time: \(getCurrentTimestamp())")
        logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        var eventName = String(describing: event)
        let activityName = String(describing: activity)

        logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logMessage("🔍 DEBUG: Threshold Event Triggered")
        logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logMessage("📝 Raw Event Name: \(eventName)")
        logMessage("📝 Activity Name: \(activityName)")

        // Clean up the event name - remove Swift type wrapper if present
        // e.g., 'Name(rawValue: "TabnovaEMM.com.google.ios.youtube.threshold.5min")' -> 'TabnovaEMM.com.google.ios.youtube.threshold.5min'
        if eventName.contains("rawValue:") {
            if let startIndex = eventName.range(of: "\"")?.upperBound,
               let endIndex = eventName.lastIndex(of: "\"") {
                eventName = String(eventName[startIndex..<endIndex])
                logMessage("📝 Cleaned Event Name: \(eventName)")
            }
        }

        // Parse the event name to extract bundle ID, event type, and threshold
        // New Format: "TabnovaEMM.<bundleId>.(threshold|limit).<X>min"
        // Example: "TabnovaEMM.com.google.ios.youtube.threshold.5min"
        let components = eventName.components(separatedBy: ".")
        logMessage("📝 Event Components: \(components)")

        // Extract bundle ID - everything between "TabnovaEMM" and "threshold"/"limit"
        var bundleId: String?
        var eventType: String?
        var thresholdMinutes = 5

        if components.count >= 4 && components[0] == "TabnovaEMM" {
            // Find "threshold" or "limit" index
            if let thresholdIndex = components.firstIndex(of: "threshold") {
                eventType = "threshold"
                // Bundle ID is everything between TabnovaEMM and threshold
                bundleId = components[1..<thresholdIndex].joined(separator: ".")
                // Extract minutes from last component
                if let lastComponent = components.last, lastComponent.hasSuffix("min") {
                    let minutesString = lastComponent.replacingOccurrences(of: "min", with: "")
                    if let extractedMinutes = Int(minutesString), extractedMinutes > 0 {
                        thresholdMinutes = extractedMinutes
                    }
                }
            } else if let limitIndex = components.firstIndex(of: "limit") {
                eventType = "limit"
                bundleId = components[1..<limitIndex].joined(separator: ".")
                if let lastComponent = components.last, lastComponent.hasSuffix("min") {
                    let minutesString = lastComponent.replacingOccurrences(of: "min", with: "")
                    if let extractedMinutes = Int(minutesString), extractedMinutes > 0 {
                        thresholdMinutes = extractedMinutes
                    }
                }
            }
        }

        logMessage("📱 Extracted Bundle ID: \(bundleId ?? "unknown")")
        logMessage("🔖 Event Type: \(eventType ?? "unknown")")
        logMessage("⏱️  Minutes: \(thresholdMinutes)")
        logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Handle limit event (shield the specific app)
        if eventType == "limit", let appBundleId = bundleId {
            logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            logMessage("🛡️ DAILY LIMIT REACHED - APPLYING SHIELD")
            logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            logMessage("📱 App: \(appBundleId)")
            logMessage("⏱️  Limit: \(thresholdMinutes) minutes")
            logMessage("🕒 Time: \(getCurrentTimestamp())")
            logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            applyShieldToApp(bundleId: appBundleId)

            logMessage("✅ Shield applied to \(appBundleId)")
            logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            return
        }

        // Handle threshold event (report usage for specific app)
        if eventType == "threshold", let appBundleId = bundleId {
            logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            logMessage("⚠️ THRESHOLD REACHED!")
            logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            logMessage("📱 App: \(appBundleId)")
            logMessage("⏱️  Threshold: \(thresholdMinutes) minutes")
            logMessage("🕒 Time: \(getCurrentTimestamp())")
            logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            let applicationName = getAppNameFromBundleId(appBundleId)
            logMessage("📝 Application Name: \(applicationName)")
            logMessage("📊 Total Usage: \(thresholdMinutes) minutes")

            // Save threshold event to shared storage for server reporting
            saveThresholdEvent(bundleIdentifier: appBundleId,
                              applicationName: applicationName,
                              thresholdMinutes: thresholdMinutes)

            logMessage("✅ Threshold event saved - will be reported to server")
            logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            return
        }

        logMessage("⚠️ Could not parse event name properly")
        logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    // MARK: - Shield Management

    // Apply shield to a specific app
    private func applyShieldToApp(bundleId: String) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.tabnova.enterprise") else {
            logMessage("⚠️ Could not access shared defaults")
            return
        }

        // Load the selection for this specific app
        guard let selectionData = sharedDefaults.data(forKey: "monitoredSelection.\(bundleId)"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selectionData) else {
            logMessage("⚠️ Could not load monitored selection for \(bundleId)")
            return
        }

        logMessage("🛡️ Applying shield to \(bundleId)")

        // Create a unique store for this app
        let store = ManagedSettingsStore(named: ManagedSettingsStore.Name(bundleId))
        store.shield.applications = selection.applicationTokens

        // Mark this app as shielded
        var shieldedApps = sharedDefaults.array(forKey: "shieldedApps") as? [String] ?? []
        if !shieldedApps.contains(bundleId) {
            shieldedApps.append(bundleId)
            logMessage("  🛡️ Added \(bundleId) to shielded list")
        }
        sharedDefaults.set(shieldedApps, forKey: "shieldedApps")
        sharedDefaults.synchronize()

        logMessage("✅ Shield applied successfully to \(bundleId)")
    }

    // Legacy method - kept for backward compatibility
    private func applyShield() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.tabnova.enterprise"),
              let selectionData = sharedDefaults.data(forKey: "monitoredSelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selectionData) else {
            logMessage("⚠️ Could not load monitored selection for shielding")
            return
        }

        logMessage("🛡️ Applying shield to \(selection.applicationTokens.count) application(s)")

        let store = ManagedSettingsStore()
        store.shield.applications = selection.applicationTokens

        // Mark apps as shielded in shared defaults
        var shieldedApps = sharedDefaults.array(forKey: "shieldedApps") as? [String] ?? []
        if let monitoredApps = sharedDefaults.dictionary(forKey: "monitoredApplications") as? [String: Int] {
            for bundleId in monitoredApps.keys {
                if !shieldedApps.contains(bundleId) {
                    shieldedApps.append(bundleId)
                    logMessage("  🛡️ Shielded: \(bundleId)")
                }
            }
        }
        sharedDefaults.set(shieldedApps, forKey: "shieldedApps")
        sharedDefaults.synchronize()

        logMessage("✅ Shield applied successfully")
    }

    // MARK: - Helper Functions

    private func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }

    private func getAppNameFromBundleId(_ bundleId: String) -> String {
        // Extract a readable name from bundle identifier
        // e.g., "com.apple.mobilesafari" -> "mobilesafari"
        if let lastComponent = bundleId.components(separatedBy: ".").last {
            return lastComponent.capitalized
        }
        return bundleId
    }

    private func logMessage(_ message: String) {
        NSLog("[DeviceActivityMonitor] \(message)")

        // Also save to shared UserDefaults for app access
        if let sharedDefaults = UserDefaults(suiteName: "group.com.tabnova.enterprise") {
            var logs = sharedDefaults.array(forKey: "activityLogs") as? [String] ?? []
            logs.append("[\(getCurrentTimestamp())] \(message)")

            // Keep only last 100 logs
            if logs.count > 100 {
                logs = Array(logs.suffix(100))
            }

            sharedDefaults.set(logs, forKey: "activityLogs")
            sharedDefaults.synchronize()
        }
    }

    private func saveThresholdEvent(bundleIdentifier: String, applicationName: String, thresholdMinutes: Int) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.tabnova.enterprise") else {
            return
        }

        let eventData: [String: Any] = [
            "bundleIdentifier": bundleIdentifier,
            "applicationName": applicationName,
            "thresholdMinutes": thresholdMinutes,
            "timestamp": Date().timeIntervalSince1970
        ]

        var events = sharedDefaults.array(forKey: "thresholdEvents") as? [[String: Any]] ?? []
        events.append(eventData)

        // Keep only last 50 events
        if events.count > 50 {
            events = Array(events.suffix(50))
        }

        sharedDefaults.set(events, forKey: "thresholdEvents")
        sharedDefaults.synchronize()

        logMessage("💾 Saved threshold event to shared storage")
    }
}
