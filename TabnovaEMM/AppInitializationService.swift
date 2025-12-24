//
//  AppInitializationService.swift
//  TabnovaEMM
//
//  Handles app initialization: permissions, auto-fetch, auto-monitoring
//

import Foundation
import FamilyControls
import SwiftUI

class AppInitializationService: ObservableObject {
    static let shared = AppInitializationService()

    @Published var isInitialized = false
    private let authorizationCenter = AuthorizationCenter.shared
    private let apiService = ApplicationAPIService()

    private init() {}

    // MARK: - Request Screen Time Permission
    func requestScreenTimePermission(completion: @escaping (Bool) -> Void) {
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logInfo("🔒 Checking Screen Time Authorization")

        let currentStatus = authorizationCenter.authorizationStatus

        switch currentStatus {
        case .notDetermined:
            logWarning("⚠️ Screen Time permission not determined, requesting...")
            requestAuthorization(completion: completion)
        case .denied:
            logError("❌ Screen Time permission denied")
            logWarning("⚠️ Re-requesting permission...")
            requestAuthorization(completion: completion)
        case .approved:
            logSuccess("✅ Screen Time permission already granted")
            logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            completion(true)
        @unknown default:
            logWarning("⚠️ Unknown authorization status")
            requestAuthorization(completion: completion)
        }
    }

    private func requestAuthorization(completion: @escaping (Bool) -> Void) {
        Task {
            do {
                try await authorizationCenter.requestAuthorization(for: .individual)

                await MainActor.run {
                    let newStatus = authorizationCenter.authorizationStatus
                    if newStatus == .approved {
                        logSuccess("✅ Screen Time permission granted!")
                        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        completion(true)
                    } else {
                        logError("❌ Screen Time permission denied by user")
                        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        completion(false)
                    }
                }
            } catch {
                await MainActor.run {
                    logError("❌ Error requesting Screen Time permission: \(error.localizedDescription)")
                    logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    completion(false)
                }
            }
        }
    }

    // MARK: - Auto-fetch application list and start monitoring
    func initializeAppMonitoring() {
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logInfo("🚀 Initializing App Monitoring")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // 1. Fetch application list from server
        logNetwork("📡 Fetching application list from server...")
        apiService.fetchApplicationList()

        // 2. Auto-add YouTube Music and start monitoring
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.setupYouTubeMusicMonitoring()
        }

        isInitialized = true
    }

    // MARK: - Setup YouTube Music monitoring
    private func setupYouTubeMusicMonitoring() {
        let youtubeMusicBundleId = "com.google.ios.youtubemusic"
        let dailyLimit = 10  // 10 minutes

        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logApp("📱 Setting up YouTube Music Monitoring")
        logInfo("Package: \(youtubeMusicBundleId)")
        logTime("Daily Limit: \(dailyLimit) minutes")
        logTime("Threshold Intervals: 5 minutes")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Start monitoring YouTube Music with 5-minute thresholds
        let appsToMonitor = [(bundleIdentifier: youtubeMusicBundleId, dailyLimitMinutes: dailyLimit)]
        AppUsageManager.shared.startMonitoringApplications(appsToMonitor)

        logSuccess("✅ YouTube Music monitoring started")
        logInfo("Threshold events will fire at 5 and 10 minute intervals")
        logInfo("Usage data will be automatically sent to server")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    // MARK: - Main initialization flow
    func performFullInitialization(completion: @escaping (Bool) -> Void) {
        // Step 1: Request Screen Time permission
        requestScreenTimePermission { [weak self] granted in
            guard granted else {
                logError("❌ Cannot initialize without Screen Time permission")
                completion(false)
                return
            }

            // Step 2: Initialize app monitoring
            self?.initializeAppMonitoring()
            completion(true)
        }
    }
}
