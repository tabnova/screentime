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
        // e.g., 'Name(rawValue: "TabnovaEMM.threshold.5min")' -> 'TabnovaEMM.threshold.5min'
        if eventName.contains("rawValue:") {
            if let startIndex = eventName.range(of: "\"")?.upperBound,
               let endIndex = eventName.lastIndex(of: "\"") {
                eventName = String(eventName[startIndex..<endIndex])
                logMessage("📝 Cleaned Event Name: \(eventName)")
            }
        }

        // Parse the event name to extract threshold minutes
        // Format: "TabnovaEMM.threshold.{minutes}min"
        let components = eventName.components(separatedBy: ".")
        logMessage("📝 Event Components: \(components)")

        var thresholdMinutes = 5  // Default to 5 minutes if extraction fails

        // Extract minutes from event name
        if let lastComponent = components.last, lastComponent.hasSuffix("min") {
            logMessage("📝 Last Component: \(lastComponent)")
            let minutesString = lastComponent.replacingOccurrences(of: "min", with: "")
            logMessage("📝 Minutes String: '\(minutesString)'")
            if let extractedMinutes = Int(minutesString), extractedMinutes > 0 {
                thresholdMinutes = extractedMinutes
                logMessage("✅ Extracted Threshold: \(thresholdMinutes) minutes")
            } else {
                logMessage("⚠️ Could not parse minutes, using default: \(thresholdMinutes) minutes")
            }
        } else {
            logMessage("⚠️ Could not extract threshold from event name!")
            logMessage("   Last component: \(components.last ?? "none")")
            logMessage("   Using default: \(thresholdMinutes) minutes")
        }
        logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Check if this is a limit event (for shielding) or threshold event (for reporting)
        let isLimitEvent = components.contains("limit")

        if isLimitEvent {
            logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            logMessage("🛡️ DAILY LIMIT REACHED - APPLYING SHIELD")
            logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            logMessage("⏱️  Limit: \(thresholdMinutes) minutes")
            logMessage("🕒 Time: \(getCurrentTimestamp())")
            logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            // Apply shield using stored FamilyActivitySelection
            applyShield()

            logMessage("✅ Shield applied to all monitored applications")
            logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            return
        }

        // Get the monitored applications from shared storage
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.tabnova.enterprise"),
              let monitoredApps = sharedDefaults.dictionary(forKey: "monitoredApplications") as? [String: Int],
              !monitoredApps.isEmpty else {
            logMessage("⚠️ No monitored applications found in shared storage")
            logMessage("Please use 'Select Apps' menu to choose apps for monitoring")
            return
        }

        logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logMessage("⚠️ THRESHOLD REACHED!")
        logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logMessage("⏱️  Threshold: \(thresholdMinutes) minutes")
        logMessage("🕒 Time: \(getCurrentTimestamp())")
        logMessage("📱 Monitored Apps: \(monitoredApps.count)")
        logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Since iOS doesn't tell us which specific app triggered the threshold,
        // we'll report usage for ALL monitored apps
        // The server will handle deduplication if needed
        for (bundleIdentifier, _) in monitoredApps {
            let applicationName = getAppNameFromBundleId(bundleIdentifier)

            logMessage("📦 Reporting usage for: \(bundleIdentifier)")
            logMessage("📱 Application: \(applicationName)")
            logMessage("⏱️  Duration: \(thresholdMinutes) minutes")

            // Save threshold event to shared storage
            saveThresholdEvent(bundleIdentifier: bundleIdentifier,
                              applicationName: applicationName,
                              thresholdMinutes: thresholdMinutes)
        }

        logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    // MARK: - Shield Management

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
