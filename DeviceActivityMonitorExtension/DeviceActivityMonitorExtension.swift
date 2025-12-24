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

        let eventName = String(describing: event)
        let activityName = String(describing: activity)

        // Parse the event name to extract threshold minutes
        // Format: "TabnovaEMM.threshold.{minutes}min"
        let components = eventName.components(separatedBy: ".")

        var thresholdMinutes = 0

        // Extract minutes from event name
        if let lastComponent = components.last, lastComponent.hasSuffix("min") {
            let minutesString = lastComponent.replacingOccurrences(of: "min", with: "")
            thresholdMinutes = Int(minutesString) ?? 0
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
