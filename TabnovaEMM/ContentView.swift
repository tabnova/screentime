//
//  ContentView.swift
//  TabnovaEMM
//
//  Created on 2024
//

import SwiftUI

struct ContentView: View {
    @State private var showSplash = true
    @State private var currentScreen: AppScreen = .splash
    @State private var isEnrolled = false
    
    enum AppScreen {
        case splash
        case welcome
        case enrollment
        case deviceConfig
        case appUsage
        case managedConfig
    }
    
    var body: some View {
        ZStack {
            switch currentScreen {
            case .splash:
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                currentScreen = .welcome
                            }
                        }
                    }
            case .welcome:
                WelcomeView(onContinue: {
                    currentScreen = .enrollment
                })
            case .enrollment:
                EnrollmentView(onEnrollmentComplete: {
                    isEnrolled = true
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
                    }
                )
            case .appUsage:
                AppUsageView(showMenu: .constant(false))
            case .managedConfig:
                ManagedConfigView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
