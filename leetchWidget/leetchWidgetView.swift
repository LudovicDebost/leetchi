import WidgetKit
import SwiftUI

// MARK: - Entry View (dispatches by family)

struct LeetchWidgetView: View {
    var entry: TCLEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        case .systemLarge:  LargeWidgetView(entry: entry)
        default:            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (next departure for first line)

struct SmallWidgetView: View {
    let entry: TCLEntry
    private var first: TCLDeparture? { entry.departures.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            Spacer(minLength: 0)
            if let err = entry.errorMessage {
                errorContent(message: err)
            } else if let d = first {
                smallDeparture(d)
            } else {
                emptyContent
            }
            Spacer(minLength: 0)
        }
        .padding(12)
    }

    private var header: some View {
        HStack {
            Image(systemName: "tram.fill").foregroundStyle(.blue)
            Text("TCL").font(.caption).fontWeight(.bold).foregroundStyle(.blue)
            Spacer()
            Text(entry.date, style: .time).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func smallDeparture(_ d: TCLDeparture) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            LineTag(line: d.line)
            Text(d.stopName).font(.caption2).lineLimit(1)
            if let t = d.nextTime {
                Text(t).font(.title2).fontWeight(.bold)
            }
            if d.times.count > 1 {
                Text(d.times[1]).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            Text("Erreur").font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyContent: some View {
        Text("Aucun passage")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Medium Widget (3 departures)

struct MediumWidgetView: View {
    let entry: TCLEntry
    private var departures: [TCLDeparture] { Array(entry.departures.prefix(3)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            mediumHeader
            if let err = entry.errorMessage {
                errorRow(message: err)
            } else if departures.isEmpty {
                Text("Aucun passage disponible").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(departures) { departure in
                    MediumDepartureRow(departure: departure)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
    }

    private var mediumHeader: some View {
        HStack {
            Image(systemName: "tram.fill").foregroundStyle(.blue)
            Text("TCL").font(.caption).fontWeight(.bold).foregroundStyle(.blue)
            Spacer()
            Text(entry.date, style: .time).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func errorRow(message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            Text("Impossible de charger les données").font(.caption)
        }
    }
}

struct MediumDepartureRow: View {
    let departure: TCLDeparture

    var body: some View {
        HStack(spacing: 8) {
            LineTag(line: departure.line)
            VStack(alignment: .leading, spacing: 1) {
                Text(departure.stopName).font(.caption2).fontWeight(.medium).lineLimit(1)
                Text("→ \(departure.direction)").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(departure.times.prefix(2), id: \.self) { time in
                    Text(time)
                        .font(.caption2).fontWeight(.semibold)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }
}

// MARK: - Large Widget (up to 7 departures)

struct LargeWidgetView: View {
    let entry: TCLEntry
    private var departures: [TCLDeparture] { Array(entry.departures.prefix(7)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            largeHeader
            Divider()
            if let err = entry.errorMessage {
                Spacer()
                errorContent(message: err)
                Spacer()
            } else if departures.isEmpty {
                Text("Aucun passage disponible").font(.caption).foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(Array(departures.enumerated()), id: \.offset) { idx, departure in
                    LargeDepartureRow(departure: departure)
                    if idx < departures.count - 1 { Divider() }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(12)
    }

    private var largeHeader: some View {
        HStack {
            Image(systemName: "tram.fill").foregroundStyle(.blue)
            Text("Prochains passages TCL").font(.caption).fontWeight(.bold).foregroundStyle(.blue)
            Spacer()
            Text(entry.date, style: .time).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundStyle(.orange)
            Text("Impossible de charger les données").font(.caption).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LargeDepartureRow: View {
    let departure: TCLDeparture

    var body: some View {
        HStack(spacing: 8) {
            LineTag(line: departure.line)
            VStack(alignment: .leading, spacing: 1) {
                Text(departure.stopName).font(.subheadline).fontWeight(.medium).lineLimit(1)
                Text("→ \(departure.direction)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(departure.times.prefix(3), id: \.self) { time in
                    Text(time)
                        .font(.caption).fontWeight(.semibold)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    LeetchWidget()
} timeline: {
    TCLEntry.placeholder
    TCLEntry(date: Date(), departures: [], configuration: .default, errorMessage: nil)
    TCLEntry(date: Date(), departures: [], configuration: .default, errorMessage: "Connection failed")
}

#Preview("Medium", as: .systemMedium) {
    LeetchWidget()
} timeline: {
    TCLEntry.placeholder
}

#Preview("Large", as: .systemLarge) {
    LeetchWidget()
} timeline: {
    TCLEntry.placeholder
}
