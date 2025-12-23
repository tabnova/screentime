import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var appUsageManager = AppUsageManager.shared
    @State private var selection = FamilyActivitySelection()
    @State private var showSuccessAlert = false

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
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .padding(.leading, 20)
                        }

                        Spacer()

                        Text("Select Apps to Monitor")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        // Invisible placeholder for symmetry
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundColor(.clear)
                            .padding(.trailing, 20)
                    }
                }
                .frame(height: 100)

                // Instructions
                VStack(spacing: 15) {
                    Image(systemName: "apps.iphone")
                        .font(.system(size: 50))
                        .foregroundColor(Color(hex: "1A9B8E"))
                        .padding(.top, 30)

                    Text("Select Apps for Monitoring")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)

                    Text("Choose apps you want to monitor with 5-minute threshold alerts. For example, select YouTube Music to track usage in 5-minute intervals.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    // Selection count
                    if !selection.applicationTokens.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("\(selection.applicationTokens.count) app(s) selected")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding()
                    }
                }
                .padding(.bottom, 20)

                // FamilyActivityPicker
                FamilyActivityPicker(selection: $selection)
                    .padding(.horizontal, 20)

                Spacer()

                // Save Button
                Button(action: {
                    saveSelection()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        Text("Start Monitoring Selected Apps")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selection.applicationTokens.isEmpty ? Color.gray : Color(hex: "1A9B8E"))
                    .cornerRadius(25)
                }
                .disabled(selection.applicationTokens.isEmpty)
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
        .alert("Monitoring Started", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Successfully started monitoring \(selection.applicationTokens.count) app(s) with 5-minute thresholds. Check the Logs menu to see threshold events.")
        }
    }

    private func saveSelection() {
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logInfo("User selected \(selection.applicationTokens.count) app(s) for monitoring")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Start monitoring with the selected apps using 10-minute threshold
        appUsageManager.startMonitoringWithSelection(selection, thresholdMinutes: 10)

        logSuccess("Started monitoring with FamilyActivityPicker selection")
        logInfo("Threshold events will fire at 5 and 10 minute intervals")
        logInfo("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        showSuccessAlert = true
    }
}

struct AppSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        AppSelectionView()
    }
}
