//
//  AppUsageView.swift
//  TabnovaEMM
//
//  Created on 2024
//

import SwiftUI
import FamilyControls

struct AppUsageView: View {
    @StateObject private var usageManager = AppUsageManager.shared
    @Binding var showMenu: Bool
    @State private var selectedTimeRange: TimeRange = .today
    @Environment(\.dismiss) private var dismiss

    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
    }

    var body: some View {
        ZStack {
            Color(hex: "E8E8E8")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Authorization Status Card
                        if !usageManager.isAuthorized {
                            authorizationCard
                        }

                        // Screen Time Summary Card
                        if usageManager.isAuthorized {
                            screenTimeSummaryCard
                        }

                        // Time Range Picker
                        if usageManager.isAuthorized {
                            timeRangePicker
                        }

                        // Category Breakdown
                        if usageManager.isAuthorized && !usageManager.appUsageList.isEmpty {
                            categoryBreakdownCard
                        }

                        // App Usage List
                        if usageManager.isAuthorized {
                            appUsageListSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }

            // Loading Overlay
            if usageManager.isLoading {
                loadingOverlay
            }
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        ZStack {
            Color(hex: "1A9B8E")
                .ignoresSafeArea(edges: .top)

            HStack {
                Button(action: {
                    showMenu.toggle()
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding(.leading, 20)
                }

                Spacer()

                Text("App Usage")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    usageManager.refreshData()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(.trailing, 20)
                }
            }
        }
        .frame(height: 100)
    }

    // MARK: - Authorization Card
    private var authorizationCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "1A9B8E").opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "hourglass.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "1A9B8E"))
            }

            Text("Screen Time Access Required")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)

            Text("To monitor app usage, TabnovaEMM needs permission to access Screen Time data on this device.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            HStack(spacing: 8) {
                Circle()
                    .fill(usageManager.authorizationStatus.color)
                    .frame(width: 8, height: 8)
                Text("Status: \(usageManager.authorizationStatus.description)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Button(action: {
                Task {
                    await usageManager.requestAuthorization()
                }
            }) {
                Text("Grant Permission")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "1A9B8E"))
                    .cornerRadius(25)
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)

            if let error = usageManager.errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Screen Time Summary Card
    private var screenTimeSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Total Screen Time")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                Spacer()
                Text(selectedTimeRange.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "1A9B8E"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(hex: "1A9B8E").opacity(0.1))
                    .cornerRadius(12)
            }

            HStack(alignment: .bottom, spacing: 4) {
                Text(usageManager.formattedTotalScreenTime)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(Color(hex: "1A9B8E"))
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "apps.iphone")
                            .font(.system(size: 14))
                        Text("\(usageManager.appUsageList.count) apps")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Time Range Picker
    private var timeRangePicker: some View {
        HStack(spacing: 8) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    withAnimation {
                        selectedTimeRange = range
                    }
                }) {
                    Text(range.rawValue)
                        .font(.system(size: 14, weight: selectedTimeRange == range ? .semibold : .regular))
                        .foregroundColor(selectedTimeRange == range ? .white : Color(hex: "1A9B8E"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(selectedTimeRange == range ? Color(hex: "1A9B8E") : Color.white)
                        .cornerRadius(20)
                }
            }
        }
        .padding(4)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Category Breakdown Card
    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage by Category")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)

            ForEach(usageManager.usageByCategory().prefix(5), id: \.category) { item in
                HStack(spacing: 12) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 10, height: 10)

                    Text(item.category)
                        .font(.system(size: 14))
                        .foregroundColor(.black)

                    Spacer()

                    Text(formatTime(item.time))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.color)
                                .frame(width: geometry.size.width * CGFloat(item.time / usageManager.totalScreenTime), height: 8)
                        }
                    }
                    .frame(width: 60, height: 8)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - App Usage List Section
    private var appUsageListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("App Usage Details")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                Text("\(usageManager.appUsageList.count) apps")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            if usageManager.appUsageList.isEmpty {
                emptyStateView
            } else {
                ForEach(usageManager.appUsageList) { app in
                    AppUsageRow(app: app, totalTime: usageManager.totalScreenTime)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "apps.iphone.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Usage Data")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)

            Text("App usage data will appear here once monitoring begins.")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))

                Text("Loading usage data...")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color(hex: "1A9B8E"))
            .cornerRadius(16)
        }
    }

    // MARK: - Helper Functions
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - App Usage Row
struct AppUsageRow: View {
    let app: AppUsageData
    let totalTime: TimeInterval

    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: app.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(categoryColor)
            }

            // App Info
            VStack(alignment: .leading, spacing: 4) {
                Text(app.appName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)

                Text(app.category)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()

            // Usage Time
            VStack(alignment: .trailing, spacing: 4) {
                Text(app.formattedUsageTime)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "1A9B8E"))

                Text(percentageString)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }

    private var categoryColor: Color {
        let category = AppCategory(rawValue: app.category) ?? .other
        return category.color
    }

    private var percentageString: String {
        guard totalTime > 0 else { return "0%" }
        let percentage = (app.usageTime / totalTime) * 100
        return String(format: "%.1f%%", percentage)
    }
}

// MARK: - Preview
struct AppUsageView_Previews: PreviewProvider {
    static var previews: some View {
        AppUsageView(showMenu: .constant(false))
    }
}
