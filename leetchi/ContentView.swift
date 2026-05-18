import SwiftUI
import WidgetKit

struct ContentView: View {
    @AppStorage(TCLConfiguration.keyGrandLyonBaseURL, store: UserDefaults(suiteName: TCLConfiguration.appGroupID))
    private var grandLyonBaseURL = TCLConfiguration.default.grandLyonBaseURL

    @AppStorage(TCLConfiguration.keyLines, store: UserDefaults(suiteName: TCLConfiguration.appGroupID))
    private var lines = TCLConfiguration.default.lines

    @AppStorage(TCLConfiguration.keyStops, store: UserDefaults(suiteName: TCLConfiguration.appGroupID))
    private var stops = TCLConfiguration.default.stops

    @AppStorage(TCLConfiguration.keyDirections, store: UserDefaults(suiteName: TCLConfiguration.appGroupID))
    private var directions = TCLConfiguration.default.directions

    @AppStorage(TCLConfiguration.keyUsername, store: UserDefaults(suiteName: TCLConfiguration.appGroupID))
    private var username = TCLConfiguration.default.username

    @AppStorage(TCLConfiguration.keyPassword, store: UserDefaults(suiteName: TCLConfiguration.appGroupID))
    private var password = TCLConfiguration.default.password

    @State private var tclData: TCLData = .empty
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingConfig = false

    private var configuration: TCLConfiguration {
        TCLConfiguration(grandLyonBaseURL: grandLyonBaseURL, username: username, password: password, lines: lines, stops: stops, directions: directions)
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Chargement…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if tclData.departures.isEmpty {
                    emptyView
                } else {
                    departureList
                }
            }
            .navigationTitle("TCL")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingConfig = true } label: {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await fetchData() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showingConfig, onDismiss: {
                Task { await fetchData() }
            }) {
                ConfigurationView()
            }
        }
        .task { await fetchData() }
    }

    // MARK: - Sub-views

    private var departureList: some View {
        List(tclData.departures) { departure in
            DepartureRow(departure: departure)
        }
        .listStyle(.insetGrouped)
        .refreshable { await fetchData() }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tram")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Aucun passage disponible")
                .foregroundStyle(.secondary)
            refreshButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            refreshButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var refreshButton: some View {
        Button("Réessayer") {
            Task { await fetchData() }
        }
        .buttonStyle(.bordered)
    }

    // MARK: - Networking

    private func fetchData() async {
        isLoading = true
        errorMessage = nil
        do {
            tclData = try await TCLService.shared.fetchDepartures(configuration: configuration)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Departure Row

struct DepartureRow: View {
    let departure: TCLDeparture

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                LineTag(line: departure.line)
                Text(departure.stopName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            Text("→ \(departure.direction)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(departure.times, id: \.self) { time in
                        Text(time)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
