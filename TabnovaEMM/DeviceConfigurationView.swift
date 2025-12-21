//
//  DeviceConfigurationView.swift
//  TabnovaEMM
//
//  Created on 2024
//

import SwiftUI

struct DeviceConfigurationView: View {
    @Binding var isEnrolled: Bool
    @State private var showMenu = false
    
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
                            showMenu.toggle()
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(.leading, 20)
                        }
                        
                        Spacer()
                        
                        Text("Device Configuration")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Invisible placeholder for symmetry
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 24))
                            .foregroundColor(.clear)
                            .padding(.trailing, 20)
                    }
                }
                .frame(height: 100)
                
                // Content
                ScrollView {
                    VStack(spacing: 0) {
                        // Basic Info Header
                        HStack {
                            Text("Basic Info")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(.gray)
                                .padding(.leading, 20)
                                .padding(.vertical, 15)
                            Spacer()
                        }
                        .background(Color(hex: "E8E8E8"))
                        
                        // Status Row
                        InfoRow(label: "Status", value: isEnrolled ? "ENROLLED" : "NOT ENROLLED", valueColor: isEnrolled ? .green : .red)
                        
                        Divider()
                            .padding(.leading, 20)
                        
                        // Device Name Row
                        InfoRow(label: "Device Name", value: UIDevice.current.name, valueColor: .black)
                        
                        Divider()
                            .padding(.leading, 20)
                        
                        // Device Type Row
                        InfoRow(label: "Device Type", value: UIDevice.current.model, valueColor: .black)
                        
                        Divider()
                            .padding(.leading, 20)
                        
                        // Model Name Row
                        InfoRow(label: "Model Name", value: getModelName(), valueColor: .black)
                        
                        Divider()
                            .padding(.leading, 20)
                        
                        // Software Version Row
                        InfoRow(label: "Software Version", value: UIDevice.current.systemVersion, valueColor: .black)
                    }
                    .padding(.top, 20)
                    
                    // Active Status Message
                    if isEnrolled {
                        VStack(spacing: 10) {
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
                            .padding(.top, 40)
                            
                            Text("Tabnova Enterprise is Active")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(hex: "1A9B8E"))
                                .padding(.top, 10)
                        }
                    }
                    
                    Spacer()
                        .frame(height: 50)
                }
            }
            
            // Side Menu
            if showMenu {
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
                            MenuButton(title: "Device Info", icon: "info.circle") {
                                showMenu = false
                            }
                            
                            MenuButton(title: "Settings", icon: "gear") {
                                showMenu = false
                            }
                            
                            MenuButton(title: "About", icon: "questionmark.circle") {
                                showMenu = false
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
        .animation(.easeInOut, value: showMenu)
    }
    
    private func getModelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .padding(.leading, 20)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(valueColor)
                .padding(.trailing, 20)
        }
        .padding(.vertical, 15)
        .background(Color.white)
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "1A9B8E"))
                    .frame(width: 30)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
        }
    }
}

struct DeviceConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceConfigurationView(isEnrolled: .constant(true))
    }
}
