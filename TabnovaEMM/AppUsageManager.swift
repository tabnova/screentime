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

// MARK: - Device Activity Monitor
class AppUsageMonitor: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // Called when monitoring interval starts
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Called when monitoring interval ends
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        // Called when a usage threshold is reached
    }
}

// MARK: - App Usage Manager
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
