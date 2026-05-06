import Foundation

// MARK: - API Models

struct TCLRefreshRequest: Encodable {
    let lines: String
    let directions: String
    let stop_ids: String
}

// Response: line → stop_name → direction → [time]
typealias TCLResponse = [String: [String: [String: [String]]]]

// MARK: - Domain Models

struct TCLDeparture: Identifiable, Codable, Equatable {
    var id = UUID()
    let line: String
    let stopName: String
    let direction: String
    let times: [String]

    var nextTime: String? { times.first }

    enum CodingKeys: String, CodingKey {
        case id, line, stopName, direction, times
    }
}

struct TCLData: Codable {
    let departures: [TCLDeparture]
    let fetchedAt: Date

    static let empty = TCLData(departures: [], fetchedAt: .distantPast)
}

// MARK: - Configuration

struct TCLConfiguration: Codable, Equatable {
    var serverURL: String
    var lines: String
    var stops: String
    var directions: String

    static let `default` = TCLConfiguration(
        serverURL: "https://litchi.vqlion.fr",
        lines: "C26,70",
        stops: "2294,42561",
        directions: ""
    )

    static let appGroupID = "group.fr.leetchi.shared"

    // UserDefaults keys
    static let keyServerURL  = "serverURL"
    static let keyLines      = "lines"
    static let keyStops      = "stops"
    static let keyDirections = "directions"

    static func load() -> TCLConfiguration {
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        return TCLConfiguration(
            serverURL:  defaults.string(forKey: keyServerURL)  ?? TCLConfiguration.default.serverURL,
            lines:      defaults.string(forKey: keyLines)      ?? TCLConfiguration.default.lines,
            stops:      defaults.string(forKey: keyStops)      ?? TCLConfiguration.default.stops,
            directions: defaults.string(forKey: keyDirections) ?? TCLConfiguration.default.directions
        )
    }

    func save() {
        let defaults = UserDefaults(suiteName: TCLConfiguration.appGroupID) ?? .standard
        defaults.set(serverURL,  forKey: TCLConfiguration.keyServerURL)
        defaults.set(lines,      forKey: TCLConfiguration.keyLines)
        defaults.set(stops,      forKey: TCLConfiguration.keyStops)
        defaults.set(directions, forKey: TCLConfiguration.keyDirections)
    }
}
