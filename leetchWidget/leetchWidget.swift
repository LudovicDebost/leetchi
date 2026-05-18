import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct TCLEntry: TimelineEntry {
    let date: Date
    let departures: [TCLDeparture]
    let configuration: TCLConfiguration
    let errorMessage: String?

    static let placeholder = TCLEntry(
        date: Date(),
        departures: [
            TCLDeparture(line: "C26", stopName: "Montluc", direction: "Gare Part-Dieu", times: ["14:32", "14:47"]),
            TCLDeparture(line: "70",  stopName: "Montluc", direction: "Bellecour",      times: ["14:35", "14:50"])
        ],
        configuration: .default,
        errorMessage: nil
    )
}

// MARK: - Timeline Provider

struct TCLProvider: TimelineProvider {
    func placeholder(in context: Context) -> TCLEntry {
        TCLEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (TCLEntry) -> Void) {
        if context.isPreview {
            completion(TCLEntry.placeholder)
            return
        }
        Task { completion(await fetchEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TCLEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    // MARK: - Private helpers

    private func fetchEntry() async -> TCLEntry {
        let config = TCLConfiguration.load()
        do {
            let data = try await TCLService.shared.fetchDepartures(configuration: config)
            return TCLEntry(date: Date(), departures: data.departures, configuration: config, errorMessage: nil)
        } catch {
            return TCLEntry(date: Date(), departures: [], configuration: config, errorMessage: error.localizedDescription)
        }
    }
}

// MARK: - Widget

struct LeetchWidget: Widget {
    let kind: String = "leetchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TCLProvider()) { entry in
            LeetchWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("TCL Passages")
        .description("Affiche les prochains passages TCL.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
