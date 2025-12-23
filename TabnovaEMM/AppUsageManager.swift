//
//  AppUsageManager.swift
//  TabnovaEMM
//
//  Created on 2024
//

import SwiftUI
import FamilyControls
import DeviceActivity
import ManagedSettings
import UserNotifications

// MARK: - App Usage Data Model
struct AppUsageData: Identifiable {
    let id = UUID()
    let appName: String
    let bundleIdentifier: String
    let usageTime: TimeInterval
    let category: String
    let iconName: String
    let lastUsed: Date?

    var formattedUsageTime: String {
        let hours = Int(usageTime) / 3600
        let minutes = (Int(usageTime) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - App Category
enum AppCategory: String, CaseIterable {
    case social = "Social"
    case productivity = "Productivity"
    case entertainment = "Entertainment"
    case games = "Games"
    case utilities = "Utilities"
    case education = "Education"
    case health = "Health & Fitness"
    case other = "Other"

    var iconName: String {
        switch self {
        case .social: return "person.2.fill"
        case .productivity: return "briefcase.fill"
        case .entertainment: return "tv.fill"
        case .games: return "gamecontroller.fill"
        case .utilities: return "wrench.and.screwdriver.fill"
        case .education: return "book.fill"
        case .health: return "heart.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .social: return Color.blue
        case .productivity: return Color.orange
        case .entertainment: return Color.purple
        case .games: return Color.green
        case .utilities: return Color.gray
        case .education: return Color.yellow
        case .health: return Color.red
        case .other: return Color.teal
        }
    }
}

// MARK: - App Usage Manager
// Note: DeviceActivityMonitor is implemented in the DeviceActivityMonitorExtension target
// The extension handles monitoring callbacks (intervalDidStart, intervalDidEnd, eventDidReachThreshold)
class AppUsageManager: ObservableObject {
    static let shared = AppUsageManager()

    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var appUsageList: [AppUsageData] = []
    @Published var totalScreenTime: TimeInterval = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let authorizationCenter = AuthorizationCenter.shared
    private let deviceActivityCenter = DeviceActivityCenter()
    private var monitoredApplications: [String: Int] = [:] // bundleIdentifier: dailyLimitMinutes

    enum AuthorizationStatus {
        case notDetermined
        case authorized
        case denied

        var description: String {
            switch self {
            case .notDetermined: return "Not Requested"
            case .authorized: return "Authorized"
            case .denied: return "Denied"
            }
        }

        var color: Color {
            switch self {
            case .notDetermined: return .orange
            case .authorized: return .green
            case .denied: return .red
            }
        }
    }

    init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization
    func checkAuthorizationStatus() {
        switch authorizationCenter.authorizationStatus {
        case .notDetermined:
            authorizationStatus = .notDetermined
            isAuthorized = false
        case .approved:
            authorizationStatus = .authorized
            isAuthorized = true
            loadAppUsageData()
        case .denied:
            authorizationStatus = .denied
            isAuthorized = false
        @unknown default:
            authorizationStatus = .notDetermined
            isAuthorized = false
        }
    }

    @MainActor
    func requestAuthorization() async {
        isLoading = true
        errorMessage = nil

        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            isAuthorized = true
            authorizationStatus = .authorized
            loadAppUsageData()
        } catch {
            isAuthorized = false
            authorizationStatus = .denied
            errorMessage = "Authorization failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Device Activity Monitoring
    func startMonitoring() {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let activityName = DeviceActivityName("TabnovaEMM.DailyActivity")

        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule)
        } catch {
            errorMessage = "Failed to start monitoring: \(error.localizedDescription)"
        }
    }

    func stopMonitoring() {
        let activityName = DeviceActivityName("TabnovaEMM.DailyActivity")
        deviceActivityCenter.stopMonitoring([activityName])
    }

    // MARK: - Monitor Applications with Thresholds
    // Note: The Screen Time API requires ApplicationTokens from FamilyActivityPicker, not bundle IDs
    // This function stores the bundle IDs for reference but doesn't create per-app events
    func startMonitoringApplications(_ applications: [(bundleIdentifier: String, dailyLimitMinutes: Int)]) {
        guard isAuthorized else {
            logError("Not authorized to monitor applications")
            return
        }

        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logInfo("Starting Application Monitoring")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Store applications for later reference
        monitoredApplications.removeAll()
        for app in applications {
            monitoredApplications[app.bundleIdentifier] = app.dailyLimitMinutes
            logApp("\(app.bundleIdentifier)")
            logTime("Daily Limit: \(app.dailyLimitMinutes) minutes")

            // Log 5-minute thresholds that would be monitored
            let numThresholds = min(app.dailyLimitMinutes / 5, 12)
            if numThresholds > 0 {
                logInfo("  Thresholds: 5, 10 minutes (up to \(app.dailyLimitMinutes) min)")
            }
        }

        // Save to shared UserDefaults for extension access
        if let sharedDefaults = UserDefaults(suiteName: "group.com.tabnova.enterprise") {
            sharedDefaults.set(monitoredApplications, forKey: "monitoredApplications")
            sharedDefaults.synchronize()
            logSuccess("Saved \(monitoredApplications.count) apps to shared storage")
        }

        // Create schedule for daily monitoring (24/7)
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let activityName = DeviceActivityName("TabnovaEMM.DailyActivity")

        // Note: To monitor specific apps with events, you need to use FamilyActivitySelection
        // with ApplicationTokens obtained from FamilyActivityPicker
        // For now, we'll start monitoring without app-specific events

        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule)
            logSuccess("Started monitoring device activity")
            logWarning("Note: Full threshold monitoring requires FamilyActivityPicker integration")
            logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        } catch {
            errorMessage = "Failed to start monitoring: \(error.localizedDescription)"
            logError("Failed to start monitoring: \(error.localizedDescription)")
        }
    }

    // MARK: - Monitor with Application Selection
    // Use this method when you have a FamilyActivitySelection from FamilyActivityPicker
    func startMonitoringWithSelection(_ selection: FamilyActivitySelection, thresholdMinutes: Int) {
        guard isAuthorized else {
            print("❌ Not authorized to monitor applications")
            return
        }

        // Create schedule for daily monitoring (24/7)
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let activityName = DeviceActivityName("TabnovaEMM.DailyActivity")

        // Create events for thresholds at 5-minute intervals
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        let maxThresholds = min(thresholdMinutes / 5, 12) // Max 12 thresholds or up to limit

        for threshold in 1...maxThresholds {
            let minutes = threshold * 5
            let eventName = DeviceActivityEvent.Name("TabnovaEMM.threshold.\(minutes)min")

            // Create event with ApplicationTokens from selection
            let event = DeviceActivityEvent(
                applications: selection.applicationTokens,
                threshold: DateComponents(minute: minutes)
            )

            events[eventName] = event
            print("   ⏰ Set threshold at \(minutes) minutes")
        }

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✅ Created \(events.count) threshold events")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule, events: events)
            print("✅ Started monitoring applications with thresholds")
        } catch {
            errorMessage = "Failed to start monitoring: \(error.localizedDescription)"
            print("❌ Failed to start monitoring: \(error)")
        }
    }

    // MARK: - Load App Usage Data
    func loadAppUsageData() {
        isLoading = true

        // In a real implementation, this would fetch data from the DeviceActivity framework
        // The DeviceActivityReport extension would provide the actual usage data
        // For demonstration, we show sample data that represents what the API would return

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.appUsageList = self?.generateSampleUsageData() ?? []
            self?.totalScreenTime = self?.appUsageList.reduce(0) { $0 + $1.usageTime } ?? 0
            self?.isLoading = false
        }
    }

    func refreshData() {
        loadAppUsageData()
    }

    // MARK: - Sample Data Generator
    // This generates sample data to demonstrate the UI
    // In production, this would be replaced with actual DeviceActivity data
    private func generateSampleUsageData() -> [AppUsageData] {
        let sampleApps: [(name: String, bundle: String, time: TimeInterval, category: AppCategory, icon: String)] = [
            ("Safari", "com.apple.mobilesafari", 7200, .productivity, "safari"),
            ("Instagram", "com.burbn.instagram", 5400, .social, "camera"),
            ("YouTube", "com.google.ios.youtube", 4800, .entertainment, "play.rectangle.fill"),
            ("Messages", "com.apple.MobileSMS", 3600, .social, "message.fill"),
            ("Mail", "com.apple.mobilemail", 2700, .productivity, "envelope.fill"),
            ("Twitter", "com.atebits.Tweetie2", 2400, .social, "bubble.left.fill"),
            ("Spotify", "com.spotify.client", 2100, .entertainment, "music.note"),
            ("WhatsApp", "net.whatsapp.WhatsApp", 1800, .social, "phone.fill"),
            ("Netflix", "com.netflix.Netflix", 1500, .entertainment, "film.fill"),
            ("Slack", "com.tinyspeck.chatlyio", 1200, .productivity, "bubble.left.and.bubble.right.fill"),
            ("Photos", "com.apple.mobileslideshow", 900, .utilities, "photo.fill"),
            ("Calendar", "com.apple.mobilecal", 600, .productivity, "calendar"),
            ("Settings", "com.apple.Preferences", 300, .utilities, "gear"),
            ("App Store", "com.apple.AppStore", 240, .utilities, "bag.fill"),
            ("Clock", "com.apple.mobiletimer", 180, .utilities, "clock.fill")
        ]

        return sampleApps.map { app in
            AppUsageData(
                appName: app.name,
                bundleIdentifier: app.bundle,
                usageTime: app.time,
                category: app.category.rawValue,
                iconName: app.icon,
                lastUsed: Date().addingTimeInterval(-Double.random(in: 0...3600))
            )
        }
    }

    // MARK: - Utility Functions
    var formattedTotalScreenTime: String {
        let hours = Int(totalScreenTime) / 3600
        let minutes = (Int(totalScreenTime) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    func usageByCategory() -> [(category: String, time: TimeInterval, color: Color)] {
        var categoryUsage: [String: TimeInterval] = [:]

        for app in appUsageList {
            categoryUsage[app.category, default: 0] += app.usageTime
        }

        return categoryUsage.map { (category, time) in
            let appCategory = AppCategory(rawValue: category) ?? .other
            return (category: category, time: time, color: appCategory.color)
        }.sorted { $0.time > $1.time }
    }
}

// MARK: - DeviceActivity Name Extension
extension DeviceActivityName {
    static let daily = Self("TabnovaEMM.DailyActivity")
}

// MARK: - DeviceActivity Event Name Extension
extension DeviceActivityEvent.Name {
    static let screenTimeThreshold = Self("TabnovaEMM.ScreenTimeThreshold")
}
