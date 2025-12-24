import SwiftUI

struct ManagedConfigView: View {
    @StateObject private var configManager = ManagedConfigManager.shared
    @StateObject private var apiService = ApplicationAPIService()
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

                        Spacer().frame(height: 50)
                    }
                }
            }
        }
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

#Preview {
    ManagedConfigView()
}
