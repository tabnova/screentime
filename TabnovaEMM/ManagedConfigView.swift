import SwiftUI
import FamilyControls
import ManagedSettings

struct ManagedConfigView: View {
    @StateObject private var configManager = ManagedConfigManager.shared
    @StateObject private var apiService = ApplicationAPIService()
    @StateObject private var shieldManager = ShieldManager.shared
    @StateObject private var appUsageManager = AppUsageManager.shared
    @State private var selectedAppForMonitoring: ApplicationData?
    @State private var showFamilyActivityPicker = false
    @State private var monitoredAppsTokens: [String: String] = [:] // bundleId -> token string
    var onNavigateBack: (() -> Void)?

    var body: some View {
        ZStack {
            Color(hex: "E8E8E8")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                ZStack {
                    Color(hex: "1A9B8E")
                        .ignoresSafeArea(edges: .top)

                    HStack {
                        Button(action: {
                            onNavigateBack?()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .padding(.leading, 20)
                        }

                        Spacer()

                        Text("Configuration")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        // Invisible placeholder for symmetry
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18))
                            .foregroundColor(.clear)
                            .padding(.trailing, 20)
                    }
                }
                .frame(height: 100)

                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Configuration Section
                        VStack(spacing: 0) {
                            // Section Header
                            HStack {
                                Text("Device Configuration")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.leading, 20)
                                    .padding(.vertical, 15)
                                Spacer()
                            }
                            .background(Color.white)

                            Divider()

                            // Email
                            ConfigInfoRow(label: "Email", value: configManager.email, icon: "envelope.fill")
                            Divider().padding(.leading, 20)

                            // Profile ID
                            ConfigInfoRow(label: "Profile ID", value: configManager.profileId, icon: "person.badge.key.fill")
                            Divider().padding(.leading, 20)

                            // Serial Number
                            ConfigInfoRow(label: "Serial Number", value: configManager.serialNumber, icon: "number")
                            Divider().padding(.leading, 20)

                            // Authorization (masked)
                            ConfigInfoRow(
                                label: "Authorization",
                                value: configManager.authorization.isEmpty ? "Not set" : "•••" + String(configManager.authorization.suffix(20)),
                                icon: "key.fill"
                            )
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Actions Section
                        VStack(spacing: 15) {
                            // Fetch Applications Button
                            Button(action: {
                                apiService.fetchApplicationList()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Fetch Application List")
                                        .font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                    if apiService.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(hex: "1A9B8E"))
                                .cornerRadius(10)
                            }
                            .disabled(apiService.isLoading)

                            // Status Message
                            if let errorMessage = apiService.errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text(errorMessage)
                                        .font(.system(size: 14))
                                        .foregroundColor(.red)
                                }
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            } else if !apiService.applications.isEmpty {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Loaded \(apiService.applications.count) applications")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Applications List Section
                        if !apiService.applications.isEmpty {
                            VStack(spacing: 0) {
                                // Section Header
                                HStack {
                                    Text("Applications List")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black)
                                        .padding(.leading, 20)
                                        .padding(.vertical, 15)
                                    Spacer()
                                    Text("\(apiService.applications.count) apps")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 20)
                                }
                                .background(Color.white)

                                Divider()

                                // Application Rows
                                ForEach(Array(apiService.applications.enumerated()), id: \.offset) { index, app in
                                    ApplicationRow(
                                        application: app,
                                        isMonitored: isAppMonitored(app.packageName),
                                        isShielded: shieldManager.isAppShielded(app.packageName),
                                        appToken: monitoredAppsTokens[app.packageName],
                                        onStartMonitoring: {
                                            selectedAppForMonitoring = app
                                            showFamilyActivityPicker = true
                                        },
                                        onStopMonitoring: {
                                            stopMonitoring(app: app)
                                        },
                                        onToggleShield: {
                                            toggleShield(bundleId: app.packageName)
                                        }
                                    )
                                    if index < apiService.applications.count - 1 {
                                        Divider().padding(.leading, 20)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .padding(.horizontal, 20)
                        }

                        // Shielded Apps Section (Blocked Apps)
                        if !shieldManager.shieldedApps.isEmpty {
                            VStack(spacing: 0) {
                                // Section Header
                                HStack {
                                    Image(systemName: "shield.fill")
                                        .foregroundColor(.orange)
                                    Text("Blocked Applications")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black)
                                        .padding(.leading, 5)
                                    Spacer()
                                    Text("\(shieldManager.shieldedApps.count) blocked")
                                        .font(.system(size: 14))
                                        .foregroundColor(.orange)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 15)
                                .background(Color.white)

                                Divider()

                                // Shielded App Rows
                                ForEach(Array(shieldManager.shieldedApps.enumerated()), id: \.element) { index, bundleId in
                                    ShieldedAppRow(bundleId: bundleId, onUnshield: {
                                        shieldManager.unshieldApp(bundleId: bundleId)
                                    })
                                    if index < shieldManager.shieldedApps.count - 1 {
                                        Divider().padding(.leading, 20)
                                    }
                                }

                                // Unshield All Button
                                if shieldManager.shieldedApps.count > 1 {
                                    Divider()
                                    Button(action: {
                                        shieldManager.unshieldAll()
                                    }) {
                                        HStack {
                                            Image(systemName: "lock.open.fill")
                                            Text("Unblock All Applications")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.green)
                                        .cornerRadius(10)
                                    }
                                    .padding(20)
                                    .background(Color.white)
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .padding(.horizontal, 20)
                        }

                        Spacer().frame(height: 50)
                    }
                }
            }
        }
        .sheet(isPresented: $showFamilyActivityPicker) {
            if let app = selectedAppForMonitoring {
                FamilyActivityPickerSheet(
                    isPresented: $showFamilyActivityPicker,
                    onSelectionComplete: { selection in
                        handleAppSelection(app: app, selection: selection)
                    }
                )
            }
        }
        .onAppear {
            loadMonitoredApps()
        }
    }

    // MARK: - Helper Methods

    private func loadMonitoredApps() {
        // Load token mappings from shared defaults
        if let sharedDefaults = UserDefaults(suiteName: "group.com.tabnova.enterprise"),
           let mappings = sharedDefaults.dictionary(forKey: "appTokenMappings") as? [String: String] {
            monitoredAppsTokens = mappings
        }
    }

    private func isAppMonitored(_ bundleId: String) -> Bool {
        return monitoredAppsTokens[bundleId] != nil
    }

    private func handleAppSelection(app: ApplicationData, selection: FamilyActivitySelection) {
        guard let token = selection.applicationTokens.first else {
            NSLog("❌ No application token selected")
            return
        }

        NSLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        NSLog("📱 Starting monitoring for: %@", app.packageName)
        NSLog("⏱️  Daily Limit: %d minutes", app.dailyLimitTimeNumber)
        NSLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Start monitoring this app with its daily limit
        appUsageManager.startMonitoringApp(
            bundleId: app.packageName,
            dailyLimitMinutes: app.dailyLimitTimeNumber,
            token: token,
            displayName: app.packageName
        )

        // Store the token
        monitoredAppsTokens[app.packageName] = String(describing: token)

        NSLog("✅ Started monitoring %@ with %d-minute limit", app.packageName, app.dailyLimitTimeNumber)
    }

    private func stopMonitoring(app: ApplicationData) {
        NSLog("🛑 Stopping monitoring for: %@", app.packageName)

        appUsageManager.stopMonitoringApp(bundleId: app.packageName)
        monitoredAppsTokens.removeValue(forKey: app.packageName)

        // Also unshield if shielded
        if shieldManager.isAppShielded(app.packageName) {
            shieldManager.unshieldApp(bundleId: app.packageName)
        }

        NSLog("✅ Stopped monitoring %@", app.packageName)
    }

    private func toggleShield(bundleId: String) {
        if shieldManager.isAppShielded(bundleId) {
            shieldManager.unshieldApp(bundleId: bundleId)
            NSLog("🔓 Unshielded: %@", bundleId)
        } else {
            // Shield the app manually
            shieldManager.shieldedApps.insert(bundleId)
            if let sharedDefaults = UserDefaults(suiteName: "group.com.tabnova.enterprise") {
                sharedDefaults.set(Array(shieldManager.shieldedApps), forKey: "shieldedApps")

                // Apply shield using the stored selection
                if let selectionData = sharedDefaults.data(forKey: "monitoredSelection.\(bundleId)"),
                   let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selectionData) {
                    let store = ManagedSettingsStore(named: ManagedSettingsStore.Name(bundleId))
                    store.shield.applications = selection.applicationTokens
                    NSLog("🛡️ Shielded: %@", bundleId)
                }
            }
        }
    }
}

// MARK: - FamilyActivityPicker Sheet
struct FamilyActivityPickerSheet: View {
    @Binding var isPresented: Bool
    @State private var selection = FamilyActivitySelection()
    let onSelectionComplete: (FamilyActivitySelection) -> Void

    var body: some View {
        NavigationView {
            VStack {
                FamilyActivityPicker(selection: $selection)
            }
            .navigationTitle("Select Application")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Done") {
                    onSelectionComplete(selection)
                    isPresented = false
                }
                .disabled(selection.applicationTokens.isEmpty)
            )
        }
    }
}

struct ShieldedAppRow: View {
    let bundleId: String
    let onUnshield: () -> Void

    var body: some View {
        HStack(spacing: 15) {
            // Shield Icon
            Image(systemName: "shield.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange)
                .frame(width: 40, height: 40)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.leading, 20)

            VStack(alignment: .leading, spacing: 4) {
                // Bundle ID
                Text(bundleId)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .lineLimit(1)

                // Status
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("Blocked - Daily limit reached")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Unblock Button
            Button(action: onUnshield) {
                Text("Unblock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(20)
            }
            .padding(.trailing, 20)
        }
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

struct ConfigInfoRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "1A9B8E"))
                .frame(width: 30)
                .padding(.leading, 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Text(value.isEmpty ? "Not set" : value)
                    .font(.system(size: 16))
                    .foregroundColor(value.isEmpty ? .red : .black)
            }

            Spacer()
        }
        .padding(.vertical, 15)
        .background(Color.white)
    }
}

struct ConfigRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value.isEmpty ? "Not set" : value)
                .font(.body)
                .foregroundColor(value.isEmpty ? .red : .primary)
        }
    }
}

struct ApplicationRow: View {
    let application: ApplicationData
    let isMonitored: Bool
    let isShielded: Bool
    let appToken: String?
    let onStartMonitoring: () -> Void
    let onStopMonitoring: () -> Void
    let onToggleShield: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 15) {
                // App Icon Placeholder
                Image(systemName: "app.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isMonitored ? Color(hex: "1A9B8E") : .gray)
                    .frame(width: 40, height: 40)
                    .background((isMonitored ? Color(hex: "1A9B8E") : Color.gray).opacity(0.1))
                    .cornerRadius(8)
                    .padding(.leading, 20)

                VStack(alignment: .leading, spacing: 4) {
                    // Package Name
                    Text(application.packageName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                        .lineLimit(1)

                    // Daily Limit Info
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "1A9B8E"))
                            Text("Limit: \(application.dailyLimitTimeNumber) min")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }

                        if application.usedLimit > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "hourglass")
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                                Text("Used: \(application.usedLimit) min")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }

                        if isMonitored {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                        }
                    }

                    // Token display (if monitored)
                    if let token = appToken {
                        Text("Token: \(token.prefix(30))...")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }

            // Control Buttons
            HStack(spacing: 10) {
                if isMonitored {
                    // Shield/Unshield Button
                    Button(action: onToggleShield) {
                        HStack(spacing: 4) {
                            Image(systemName: isShielded ? "lock.open.fill" : "shield.fill")
                                .font(.system(size: 12))
                            Text(isShielded ? "Unshield" : "Shield")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isShielded ? Color.green : Color.orange)
                        .cornerRadius(15)
                    }

                    // Stop Monitoring Button
                    Button(action: onStopMonitoring) {
                        HStack(spacing: 4) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 12))
                            Text("Stop")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(15)
                    }
                } else {
                    // Start Monitoring Button
                    Button(action: onStartMonitoring) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 12))
                            Text("Start Monitoring")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "1A9B8E"))
                        .cornerRadius(15)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

#Preview {
    ManagedConfigView()
}
