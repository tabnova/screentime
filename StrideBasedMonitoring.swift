import DeviceActivity
import FamilyControls
import Foundation

/// Example: Stride-based monitoring with 12 separate 2-hour schedules
/// Note: The current implementation in AppUsageManager.swift is more efficient
class StrideBasedMonitoring {

    private let deviceActivityCenter = DeviceActivityCenter()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.tabnova.enterprise")

    // MARK: - Start Monitoring with 12 Schedules
    func startStrideMonitoring(bundleId: String, token: ApplicationToken) {
        NSLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        NSLog("📊 Starting Stride Monitoring: \(bundleId)")
        NSLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Reset running total at start
        sharedDefaults?.set(0, forKey: "runningTotal.\(bundleId)")
        sharedDefaults?.synchronize()

        // Create 12 separate 2-hour schedules
        for hourBlock in 0..<12 {
            let startHour = hourBlock * 2
            let endHour = startHour + 1
            let endMinute = 59

            // Create schedule for this 2-hour window
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: startHour, minute: 0),
                intervalEnd: DateComponents(hour: endHour, minute: endMinute),
                repeats: true  // Repeat daily
            )

            // Create stride events: 5, 10, 15... up to 120 minutes
            var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

            for strideMinutes in stride(from: 5, through: 120, by: 5) {
                // Unique name: Usage.Hour0.Min5, Usage.Hour2.Min10, etc.
                let eventName = DeviceActivityEvent.Name("Usage.Hour\(startHour).Min\(strideMinutes)")

                let event = DeviceActivityEvent(
                    applications: Set([token]),
                    threshold: DateComponents(minute: strideMinutes)
                )

                events[eventName] = event
                NSLog("   Created event: \(eventName.rawValue) @ \(strideMinutes) min")
            }

            // Unique activity name for this 2-hour block
            let activityName = DeviceActivityName("TabnovaEMM.\(bundleId).Hour\(startHour)")

            do {
                try deviceActivityCenter.startMonitoring(activityName, during: schedule, events: events)
                NSLog("✅ Started monitoring: Hour \(startHour)-\(endHour)")
            } catch {
                NSLog("❌ Failed Hour \(startHour): \(error.localizedDescription)")
            }
        }

        NSLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    // MARK: - Stop All Stride Monitoring
    func stopStrideMonitoring(bundleId: String) {
        var activities: [DeviceActivityName] = []

        for hourBlock in 0..<12 {
            let startHour = hourBlock * 2
            let activityName = DeviceActivityName("TabnovaEMM.\(bundleId).Hour\(startHour)")
            activities.append(activityName)
        }

        deviceActivityCenter.stopMonitoring(activities)
        NSLog("🛑 Stopped all stride monitoring for \(bundleId)")
    }
}

// MARK: - DeviceActivityMonitor Extension Handler
extension DeviceActivityMonitor {

    /// Parse stride-based event names: "Usage.Hour0.Min5"
    func handleStrideEvent(_ event: DeviceActivityEvent.Name, bundleId: String) {
        let eventString = event.rawValue
        let components = eventString.split(separator: ".")

        guard components.count == 3,
              components[0] == "Usage",
              components[1].hasPrefix("Hour"),
              components[2].hasPrefix("Min") else {
            NSLog("⚠️ Invalid stride event format: \(eventString)")
            return
        }

        // Parse hour and minutes
        let hourString = components[1].dropFirst(4)  // Remove "Hour"
        let minString = components[2].dropFirst(3)    // Remove "Min"

        guard let startHour = Int(hourString),
              let strideMinutes = Int(minString) else {
            NSLog("⚠️ Could not parse hour/minutes from: \(eventString)")
            return
        }

        NSLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        NSLog("📊 STRIDE THRESHOLD HIT")
        NSLog("   Event: \(eventString)")
        NSLog("   Hour Block: \(startHour):00-\(startHour+1):59")
        NSLog("   Stride Milestone: \(strideMinutes) minutes")
        NSLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Get running total from previous blocks
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.tabnova.enterprise") else {
            NSLog("❌ Could not access shared defaults")
            return
        }

        let previousTotal = sharedDefaults.integer(forKey: "runningTotal.\(bundleId)")

        // Current block usage = stride minutes
        // Total daily usage = previous blocks + current block
        let totalDailyUsage = previousTotal + strideMinutes

        NSLog("📈 Usage Calculation:")
        NSLog("   Previous blocks total: \(previousTotal) min")
        NSLog("   Current block usage: \(strideMinutes) min")
        NSLog("   Total daily usage: \(totalDailyUsage) min")
        NSLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Save the event for reporting to server
        saveStrideThresholdEvent(
            bundleIdentifier: bundleId,
            startHour: startHour,
            strideMinutes: strideMinutes,
            totalDailyUsage: totalDailyUsage
        )
    }

    /// Handle interval end (when 2-hour block ends)
    func handleIntervalDidEnd(for bundleId: String, startHour: Int, finalUsage: Int) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.tabnova.enterprise") else {
            return
        }

        // Update running total for next block
        let previousTotal = sharedDefaults.integer(forKey: "runningTotal.\(bundleId)")
        let newTotal = previousTotal + finalUsage
        sharedDefaults.set(newTotal, forKey: "runningTotal.\(bundleId)")
        sharedDefaults.synchronize()

        NSLog("🔄 Interval ended - Hour \(startHour)")
        NSLog("   Block usage: \(finalUsage) min")
        NSLog("   Running total updated: \(newTotal) min")
    }

    private func saveStrideThresholdEvent(bundleIdentifier: String, startHour: Int, strideMinutes: Int, totalDailyUsage: Int) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.tabnova.enterprise") else {
            return
        }

        let event: [String: Any] = [
            "bundleIdentifier": bundleIdentifier,
            "startHour": startHour,
            "strideMinutes": strideMinutes,
            "totalDailyUsage": totalDailyUsage,
            "timestamp": Date().timeIntervalSince1970
        ]

        var events = sharedDefaults.array(forKey: "strideThresholdEvents") as? [[String: Any]] ?? []
        events.append(event)
        sharedDefaults.set(events, forKey: "strideThresholdEvents")
        sharedDefaults.synchronize()

        NSLog("💾 Saved stride event to shared storage")
    }
}

// MARK: - Usage Example
/*

 // To use this stride-based system:

 1. Start monitoring:
 let monitor = StrideBasedMonitoring()
 monitor.startStrideMonitoring(bundleId: "com.snapchat.app", token: snapchatToken)

 2. In your DeviceActivityMonitorExtension.swift, update eventDidReachThreshold:

 override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
     super.eventDidReachThreshold(event, activity: activity)

     // Parse activity name to get bundle ID
     let activityString = activity.rawValue
     // Format: "TabnovaEMM.<bundleId>.Hour0"

     if activityString.hasPrefix("TabnovaEMM.") {
         let parts = activityString.split(separator: ".")
         if parts.count >= 3 {
             let bundleIdParts = parts[1..<(parts.count-1)]
             let bundleId = bundleIdParts.joined(separator: ".")

             handleStrideEvent(event, bundleId: bundleId)
         }
     }
 }

 3. In intervalDidEnd, save the running total:

 override func intervalDidEnd(for activity: DeviceActivityName) {
     super.intervalDidEnd(for: activity)

     // Parse to get bundle ID and hour
     let activityString = activity.rawValue
     // Extract hour from "TabnovaEMM.<bundleId>.Hour0"

     // Get the final usage for this block and update running total
     handleIntervalDidEnd(for: bundleId, startHour: hour, finalUsage: finalBlockUsage)
 }

 */
