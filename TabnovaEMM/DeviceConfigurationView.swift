//
//  DeviceConfigurationView.swift
//  TabnovaEMM
//
//  Created on 2024
//

import SwiftUI
import SystemConfiguration.CaptiveNetwork
import CoreTelephony
import Network

struct DeviceConfigurationView: View {
    @Binding var isEnrolled: Bool
    @Binding var showMenu: Bool
    var onNavigateToAppUsage: () -> Void
    @StateObject private var deviceInfo = DeviceInfoManager()

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

                        // Refresh button
                        Button(action: {
                            deviceInfo.refresh()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(.trailing, 20)
                        }
                    }
                }
                .frame(height: 100)

                // Content
                ScrollView {
                    VStack(spacing: 0) {
                        // Basic Info Header
                        SectionHeader(title: "Basic Info")

                        // Status Row
                        InfoRow(label: "Status", value: isEnrolled ? "ENROLLED" : "NOT ENROLLED", valueColor: isEnrolled ? .green : .red)

                        Divider().padding(.leading, 20)

                        // Device Name Row
                        InfoRow(label: "Device Name", value: UIDevice.current.name, valueColor: .black)

                        Divider().padding(.leading, 20)

                        // Device Type Row
                        InfoRow(label: "Device Type", value: UIDevice.current.model, valueColor: .black)

                        Divider().padding(.leading, 20)

                        // Model Name Row
                        InfoRow(label: "Model Name", value: deviceInfo.modelName, valueColor: .black)

                        Divider().padding(.leading, 20)

                        // Model Number Row
                        InfoRow(label: "Model Number", value: deviceInfo.modelNumber, valueColor: .black)

                        Divider().padding(.leading, 20)

                        // Serial Number Row
                        InfoRow(label: "Serial Number", value: deviceInfo.serialNumber, valueColor: .black)

                        Divider().padding(.leading, 20)

                        // Software Version Row
                        InfoRow(label: "Software Version", value: UIDevice.current.systemVersion, valueColor: .black)

                        // Network Info Header
                        SectionHeader(title: "Network Info")

                        // WiFi Address Row
                        InfoRow(label: "WiFi Address", value: deviceInfo.wifiAddress, valueColor: .black)

                        Divider().padding(.leading, 20)

                        // Bluetooth ID Row
                        InfoRow(label: "Bluetooth ID", value: deviceInfo.bluetoothID, valueColor: .black)

                        Divider().padding(.leading, 20)

                        // SE ID Row
                        InfoRow(label: "SE ID", value: deviceInfo.seID, valueColor: .black)

                        Divider().padding(.leading, 20)

                        // WiFi AP Row
                        InfoRow(label: "WiFi AP", value: deviceInfo.currentWiFiSSID, valueColor: .black)

                        // Mobile Network Header
                        SectionHeader(title: "Mobile Network")

                        // Operator Name Row
                        InfoRow(label: "Operator Name", value: deviceInfo.carrierName, valueColor: .black)

                        Divider().padding(.leading, 20)

                        // Connection Status Row
                        InfoRow(label: "Connection Status", value: deviceInfo.connectionStatus, valueColor: deviceInfo.isConnected ? .green : .red)

                        Divider().padding(.leading, 20)

                        // Mobile Data Status Row
                        InfoRow(label: "Mobile Data", value: deviceInfo.mobileDataStatus, valueColor: deviceInfo.isMobileDataEnabled ? .green : .orange)

                        // Battery Info Header
                        SectionHeader(title: "Battery")

                        // Battery Level Row
                        BatteryRow(level: deviceInfo.batteryLevel, state: deviceInfo.batteryState)
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
        }
        .onAppear {
            deviceInfo.startMonitoring()
        }
        .onDisappear {
            deviceInfo.stopMonitoring()
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.gray)
                .padding(.leading, 20)
                .padding(.vertical, 15)
            Spacer()
        }
        .background(Color(hex: "E8E8E8"))
    }
}

// MARK: - Info Row
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
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 15)
        .background(Color.white)
    }
}

// MARK: - Battery Row
struct BatteryRow: View {
    let level: Float
    let state: UIDevice.BatteryState

    var body: some View {
        HStack {
            Text("Battery Level")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .padding(.leading, 20)

            Spacer()

            HStack(spacing: 8) {
                // Battery icon
                Image(systemName: batteryIconName)
                    .font(.system(size: 20))
                    .foregroundColor(batteryColor)

                Text(batteryPercentage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(batteryColor)

                if state == .charging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
            }
            .padding(.trailing, 20)
        }
        .padding(.vertical, 15)
        .background(Color.white)
    }

    private var batteryPercentage: String {
        if level < 0 {
            return "Unknown"
        }
        return "\(Int(level * 100))%"
    }

    private var batteryIconName: String {
        if level < 0 { return "battery.0" }
        if level <= 0.25 { return "battery.25" }
        if level <= 0.50 { return "battery.50" }
        if level <= 0.75 { return "battery.75" }
        return "battery.100"
    }

    private var batteryColor: Color {
        if level < 0 { return .gray }
        if level <= 0.20 { return .red }
        if level <= 0.40 { return .orange }
        return .green
    }
}

// MARK: - Device Info Manager
class DeviceInfoManager: ObservableObject {
    @Published var modelName: String = ""
    @Published var modelNumber: String = ""
    @Published var serialNumber: String = ""
    @Published var wifiAddress: String = ""
    @Published var bluetoothID: String = ""
    @Published var seID: String = ""
    @Published var currentWiFiSSID: String = ""
    @Published var carrierName: String = ""
    @Published var connectionStatus: String = ""
    @Published var isConnected: Bool = false
    @Published var mobileDataStatus: String = ""
    @Published var isMobileDataEnabled: Bool = false
    @Published var batteryLevel: Float = -1
    @Published var batteryState: UIDevice.BatteryState = .unknown

    private var networkMonitor: NWPathMonitor?
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")

    init() {
        refresh()
    }

    func refresh() {
        fetchModelInfo()
        fetchNetworkInfo()
        fetchCarrierInfo()
        fetchBatteryInfo()
    }

    func startMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        startNetworkMonitoring()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelDidChange),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryStateDidChange),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
    }

    func stopMonitoring() {
        networkMonitor?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func batteryLevelDidChange() {
        DispatchQueue.main.async {
            self.batteryLevel = UIDevice.current.batteryLevel
        }
    }

    @objc private func batteryStateDidChange() {
        DispatchQueue.main.async {
            self.batteryState = UIDevice.current.batteryState
        }
    }

    private func fetchModelInfo() {
        // Model Name (identifier like iPhone14,2)
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        modelName = identifier

        // Model Number - Not directly accessible, using identifier
        modelNumber = identifier

        // Serial Number - Not accessible on iOS for privacy reasons
        serialNumber = "Not Available"
    }

    private func fetchNetworkInfo() {
        // WiFi Address
        wifiAddress = getWiFiAddress() ?? "Not Available"

        // Bluetooth ID - Not directly accessible
        bluetoothID = "Not Available"

        // SE ID - Secure Element ID is not accessible
        seID = "Not Available"

        // Current WiFi SSID
        currentWiFiSSID = getCurrentWiFiSSID() ?? "Not Connected"
    }

    private func fetchCarrierInfo() {
        let networkInfo = CTTelephonyNetworkInfo()

        if let carriers = networkInfo.serviceSubscriberCellularProviders,
           let carrier = carriers.values.first {
            carrierName = carrier.carrierName ?? "Unknown"
        } else {
            carrierName = "No SIM"
        }

        // Check current radio access technology
        if let radioTech = networkInfo.serviceCurrentRadioAccessTechnology?.values.first {
            mobileDataStatus = getRadioTechnologyName(radioTech)
            isMobileDataEnabled = true
        } else {
            mobileDataStatus = "Disabled"
            isMobileDataEnabled = false
        }
    }

    private func fetchBatteryInfo() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
    }

    private func startNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self?.isConnected = true
                    if path.usesInterfaceType(.wifi) {
                        self?.connectionStatus = "WiFi"
                    } else if path.usesInterfaceType(.cellular) {
                        self?.connectionStatus = "Cellular"
                    } else if path.usesInterfaceType(.wiredEthernet) {
                        self?.connectionStatus = "Ethernet"
                    } else {
                        self?.connectionStatus = "Connected"
                    }
                } else {
                    self?.isConnected = false
                    self?.connectionStatus = "Not Connected"
                }
            }
        }
        networkMonitor?.start(queue: networkQueue)
    }

    private func getWiFiAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            guard let interface = ptr?.pointee else { continue }
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr,
                                socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        return address
    }

    private func getCurrentWiFiSSID() -> String? {
        // Note: This requires the Access WiFi Information entitlement
        // and precise location authorization on iOS 13+
        if let interfaces = CNCopySupportedInterfaces() as? [String] {
            for interface in interfaces {
                if let info = CNCopyCurrentNetworkInfo(interface as CFString) as NSDictionary? {
                    return info[kCNNetworkInfoKeySSID as String] as? String
                }
            }
        }
        return nil
    }

    private func getRadioTechnologyName(_ radioTech: String) -> String {
        switch radioTech {
        case CTRadioAccessTechnologyLTE:
            return "LTE"
        case CTRadioAccessTechnologyNRNSA, CTRadioAccessTechnologyNR:
            return "5G"
        case CTRadioAccessTechnologyWCDMA:
            return "3G (WCDMA)"
        case CTRadioAccessTechnologyHSDPA:
            return "3G (HSDPA)"
        case CTRadioAccessTechnologyHSUPA:
            return "3G (HSUPA)"
        case CTRadioAccessTechnologyEdge:
            return "2G (EDGE)"
        case CTRadioAccessTechnologyGPRS:
            return "2G (GPRS)"
        default:
            return "Mobile Data"
        }
    }
}

struct DeviceConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceConfigurationView(
            isEnrolled: .constant(true),
            showMenu: .constant(false),
            onNavigateToAppUsage: {}
        )
    }
}
