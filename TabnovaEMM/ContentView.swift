//
//  ContentView.swift
//  TabnovaEMM
//
//  Created on 2024
//

import SwiftUI

struct ContentView: View {
    @State private var currentScreen: AppScreen = .splash
    @State private var isEnrolled = false
    @State private var showMenu = false
    @State private var showAbout = false

    private let hasLaunchedKey = "hasLaunchedBefore"

    enum AppScreen {
        case splash
        case welcome
        case enrollment
        case deviceConfig
        case appUsage
    }

    var body: some View {
        ZStack {
            switch currentScreen {
            case .splash:
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                // Check if app has been launched before
                                if UserDefaults.standard.bool(forKey: hasLaunchedKey) {
                                    currentScreen = .deviceConfig
                                    isEnrolled = true
                                } else {
                                    currentScreen = .welcome
                                }
                            }
                        }
                    }
            case .welcome:
                WelcomeView(onContinue: {
                    currentScreen = .enrollment
                })
            case .enrollment:
                EnrollmentView(
                    onEnrollmentComplete: {
                        isEnrolled = true
                        UserDefaults.standard.set(true, forKey: hasLaunchedKey)
                        currentScreen = .deviceConfig
                    },
                    onCancel: {
                        // Navigate to App Usage when cancel is pressed
                        UserDefaults.standard.set(true, forKey: hasLaunchedKey)
                        currentScreen = .appUsage
                    }
                )
            case .deviceConfig:
                DeviceConfigurationView(
                    isEnrolled: $isEnrolled,
                    showMenu: $showMenu,
                    onNavigateToAppUsage: {
                        currentScreen = .appUsage
                    }
                )
            case .appUsage:
                AppUsageView(
                    showMenu: $showMenu,
                    onNavigateToDeviceConfig: {
                        currentScreen = .deviceConfig
                    }
                )
            }

            // Global Side Menu Overlay
            if showMenu {
                SideMenuView(
                    showMenu: $showMenu,
                    showAbout: $showAbout,
                    currentScreen: currentScreen,
                    onNavigateToDeviceConfig: {
                        currentScreen = .deviceConfig
                    },
                    onNavigateToAppUsage: {
                        currentScreen = .appUsage
                    }
                )
            }

            // About Dialog
            if showAbout {
                AboutDialogView(showAbout: $showAbout)
            }
        }
        .animation(.easeInOut, value: showMenu)
    }
}

// MARK: - Side Menu View
struct SideMenuView: View {
    @Binding var showMenu: Bool
    @Binding var showAbout: Bool
    let currentScreen: ContentView.AppScreen
    var onNavigateToDeviceConfig: () -> Void
    var onNavigateToAppUsage: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    showMenu = false
                }

            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Color(hex: "1A9B8E")
                        .frame(height: 100)
                        .overlay(
                            Text("Menu")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 20)
                                .padding(.top, 40)
                        )

                    VStack(alignment: .leading, spacing: 0) {
                        MenuButton(
                            title: "Device Info",
                            icon: "info.circle",
                            isSelected: currentScreen == .deviceConfig
                        ) {
                            showMenu = false
                            onNavigateToDeviceConfig()
                        }

                        MenuButton(
                            title: "App Usage",
                            icon: "hourglass.circle",
                            isSelected: currentScreen == .appUsage
                        ) {
                            showMenu = false
                            onNavigateToAppUsage()
                        }

                        MenuButton(
                            title: "Settings",
                            icon: "gear",
                            isSelected: false
                        ) {
                            showMenu = false
                        }

                        MenuButton(
                            title: "About",
                            icon: "questionmark.circle",
                            isSelected: false
                        ) {
                            showMenu = false
                            showAbout = true
                        }
                    }
                    .padding(.top, 20)

                    Spacer()
                }
                .frame(width: 280)
                .background(Color.white)
                .transition(.move(edge: .leading))

                Spacer()
            }
        }
    }
}

// MARK: - About Dialog View
struct AboutDialogView: View {
    @Binding var showAbout: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    showAbout = false
                }

            VStack(spacing: 20) {
                // Logo
                ZStack {
                    HexagonShape()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "1A9B8E"), Color(hex: "0D7A70")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    HexagonShape()
                        .fill(Color(hex: "5DDECD"))
                        .frame(width: 55, height: 55)

                    VStack(spacing: 0) {
                        Text("TABNOVA")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(Color(hex: "1A9B8E"))
                        Text("Enterprise")
                            .font(.system(size: 6, weight: .semibold))
                            .foregroundColor(Color(hex: "1A9B8E"))
                    }
                }

                Text("Tabnova Enterprise")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "1A9B8E"))

                Text("Version 2.0")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)

                Divider()
                    .padding(.horizontal, 20)

                VStack(spacing: 8) {
                    Text("Tabnova Ltd")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)

                    Text("London, UK")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Text("Mobile Device Management Solution for Enterprise")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Button(action: {
                    showAbout = false
                }) {
                    Text("Close")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 120)
                        .padding(.vertical, 12)
                        .background(Color(hex: "1A9B8E"))
                        .cornerRadius(20)
                }
                .padding(.top, 10)
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Menu Button
struct MenuButton: View {
    let title: String
    let icon: String
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "1A9B8E"))
                    .frame(width: 30)

                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color(hex: "1A9B8E") : .black)

                Spacer()

                if isSelected {
                    Circle()
                        .fill(Color(hex: "1A9B8E"))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(isSelected ? Color(hex: "1A9B8E").opacity(0.1) : Color.clear)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
