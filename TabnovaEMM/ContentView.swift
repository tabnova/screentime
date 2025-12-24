//
//  ContentView.swift
//  TabnovaEMM
//
//  Created on 2024
//

import SwiftUI
import FamilyControls

struct ContentView: View {
    @State private var showSplash = true
    @State private var currentScreen: AppScreen = .splash
    @AppStorage("isEnrolled") private var isEnrolled: Bool = false
    @AppStorage("hasAgreedToTerms") private var hasAgreedToTerms: Bool = false
    @StateObject private var initService = AppInitializationService.shared
    
    enum AppScreen {
        case splash
        case welcome
        case enrollment
        case deviceConfig
        case appUsage
        case managedConfig
        case logs
        case appSelection
    }
    
    var body: some View {
        ZStack {
            switch currentScreen {
            case .splash:
                SplashView()
                    .onAppear {
                        // Request Screen Time permission and initialize app
                        initService.performFullInitialization { success in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    // Skip to device config if already enrolled
                                    if isEnrolled {
                                        currentScreen = .deviceConfig
                                    } else {
                                        currentScreen = .welcome
                                    }
                                }
                            }
                        }
                    }
            case .welcome:
                WelcomeView(onContinue: {
                    hasAgreedToTerms = true
                    currentScreen = .enrollment
                })
            case .enrollment:
                EnrollmentView(onEnrollmentComplete: {
                    isEnrolled = true
                    // Initialize monitoring after enrollment
                    initService.performFullInitialization { _ in }
                    currentScreen = .deviceConfig
                })
            case .deviceConfig:
                DeviceConfigurationView(
                    isEnrolled: $isEnrolled,
                    onNavigateToAppUsage: {
                        currentScreen = .appUsage
                    },
                    onNavigateToManagedConfig: {
                        currentScreen = .managedConfig
                    },
                    onNavigateToLogs: {
                        currentScreen = .logs
                    },
                    onNavigateToAppSelection: {
                        currentScreen = .appSelection
                    }
                )
            case .appUsage:
                AppUsageView(showMenu: .constant(false), onNavigateBack: {
                    currentScreen = .deviceConfig
                })
            case .managedConfig:
                ManagedConfigView(onNavigateBack: {
                    currentScreen = .deviceConfig
                })
            case .logs:
                LogView()
            case .appSelection:
                AppSelectionView(onNavigateBack: {
                    currentScreen = .deviceConfig
                })
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
