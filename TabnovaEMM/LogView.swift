import SwiftUI

struct LogView: View {
    let onNavigateBack: () -> Void

    @StateObject private var logManager = LogManager.shared
    @State private var searchText = ""
    @State private var autoScroll = true

    var filteredLogs: [LogManager.LogEntry] {
        if searchText.isEmpty {
            return logManager.logs
        } else {
            return logManager.logs.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }
    }

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
                            onNavigateBack()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                        }
                        .padding(.leading, 15)

                        Spacer()

                        Text("System Logs")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        // Empty spacer to balance the back button
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.clear)
                        .padding(.trailing, 15)
                    }
                }
                .frame(height: 100)

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search logs...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(10)
                .background(Color.white)
                .cornerRadius(8)
                .padding(.horizontal, 15)
                .padding(.vertical, 10)

                // Controls
                HStack(spacing: 15) {
                    Button(action: {
                        logManager.clearLogs()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear")
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(8)
                    }

                    Button(action: {
                        autoScroll.toggle()
                    }) {
                        HStack {
                            Image(systemName: autoScroll ? "arrow.down.circle.fill" : "arrow.down.circle")
                            Text(autoScroll ? "Auto-scroll ON" : "Auto-scroll OFF")
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(autoScroll ? Color(hex: "1A9B8E") : Color.gray)
                        .cornerRadius(8)
                    }

                    Spacer()

                    Text("\(filteredLogs.count) logs")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 10)

                // Log List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(filteredLogs) { log in
                                LogEntryView(entry: log)
                                    .id(log.id)
                            }
                        }
                        .padding(15)
                    }
                    .onChange(of: logManager.logs.count) { _ in
                        if autoScroll, let lastLog = filteredLogs.last {
                            withAnimation {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct LogEntryView: View {
    let entry: LogManager.LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(entry.level.rawValue)
                    .font(.system(size: 16))

                Text(entry.formattedTimestamp)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)

                Spacer()
            }

            Text(entry.message)
                .font(.system(size: 14))
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView(onNavigateBack: {})
    }
}
