//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitorExtension
//
//  TabnovaEMM - Device Activity Monitor Extension
//  This extension handles Screen Time monitoring events
//

import DeviceActivity
import Foundation

/// Device Activity Monitor Extension
/// This extension is required by the FamilyControls framework to receive
/// callbacks when device activity events occur (interval start/end, thresholds)
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // Called when a monitoring interval starts
        // You can use this to log activity or update shared state via App Group
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Called when a monitoring interval ends
        // You can use this to summarize activity data
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        // Called when a usage threshold is reached
        // You can use this to trigger notifications or restrictions
    }
}
