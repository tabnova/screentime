import SwiftUI

struct ApplicationData: Identifiable, Codable {
    let id = UUID()
    let packageName: String
    let dailyLimitTimeNumber: Int
    let usedLimit: Int
    var used: Int = 0

    enum CodingKeys: String, CodingKey {
        case packageName = "package_name"
        case dailyLimitTimeNumber = "dailyLimitTimeNumber"
        case usedLimit
    }
}

struct ApplicationListView: View {
    @StateObject private var apiService = ApplicationAPIService.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                if apiService.isLoading {
                    ProgressView("Loading applications...")
                        .padding()
                } else if let errorMessage = apiService.errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text("Error")
                            .font(.title)
                            .fontWeight(.bold)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Retry") {
                            apiService.fetchApplicationList()
                        }
                        .padding()
                        .background(Color(hex: "#1A9B8E"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                } else if apiService.applications.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No applications found")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                } else {
                    List(apiService.applications) { app in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(app.packageName)
                                .font(.headline)
                                .foregroundColor(Color(hex: "#1A9B8E"))

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Daily Limit")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("\(app.dailyLimitTimeNumber) min")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }

                                Spacer()

                                VStack(alignment: .leading) {
                                    Text("Used Limit")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("\(app.usedLimit)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }

                                Spacer()

                                VStack(alignment: .leading) {
                                    Text("Used")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("\(app.used) min")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(app.used >= app.dailyLimitTimeNumber ? .red : .green)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("Applications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        apiService.fetchApplicationList()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                // Update usage times from tracker first
                apiService.updateUsageTimesFromTracker()
                // Then fetch latest from server
                apiService.fetchApplicationList()
            }
        }
    }
}

#Preview {
    ApplicationListView()
}
