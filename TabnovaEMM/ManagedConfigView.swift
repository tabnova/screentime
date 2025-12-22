import SwiftUI

struct ManagedConfigView: View {
    @StateObject private var configManager = ManagedConfigManager.shared
    @State private var showApplicationList = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Display managed configuration values
                VStack(alignment: .leading, spacing: 15) {
                    Text("Managed Configuration")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)

                    ConfigRow(title: "Authorization", value: configManager.authorization)
                    ConfigRow(title: "Email", value: configManager.email)
                    ConfigRow(title: "Profile ID", value: configManager.profileId)
                    ConfigRow(title: "Serial Number", value: configManager.serialNumber)
                }
                .padding()
                .background(Color(hex: "#F5F5F5"))
                .cornerRadius(10)

                // Button to request application list
                Button(action: {
                    showApplicationList = true
                }) {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                        Text("Request Application List")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#1A9B8E"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Managed Config")
            .sheet(isPresented: $showApplicationList) {
                ApplicationListView()
            }
        }
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
