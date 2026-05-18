import Foundation

// MARK: - API Models (Grand Lyon Datapusher)

struct GrandLyonResponse<T: Decodable>: Decodable {
    let values: [T]
}

struct GrandLyonPassage: Decodable {
    let ligne: String
    let direction: String
    let heurepassage: String
    let id: String
}

struct GrandLyonStop: Decodable {
    let id: String
    let nom: String
}

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
    var grandLyonBaseURL: String
    var username: String
    var password: String
    var lines: String
    var stops: String
    var directions: String

    static let `default` = TCLConfiguration(
        grandLyonBaseURL: "https://data.grandlyon.com/fr/datapusher/ws/rdata/",
        username: "",
        password: "",
        lines: "C26,70",
        stops: "2294,42561",
        directions: ""
    )

    static let appGroupID = "group.fr.leetchi.shared"

    // UserDefaults keys
    static let keyGrandLyonBaseURL = "grandLyonBaseURL"
    static let keyUsername = "grandLyonUsername"
    static let keyPassword = "grandLyonPassword"
    static let keyLines      = "lines"
    static let keyStops      = "stops"
    static let keyDirections = "directions"

    static func load() -> TCLConfiguration {
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        return TCLConfiguration(
            grandLyonBaseURL: defaults.string(forKey: keyGrandLyonBaseURL) ?? TCLConfiguration.default.grandLyonBaseURL,
            username: defaults.string(forKey: keyUsername) ?? TCLConfiguration.default.username,
            password: defaults.string(forKey: keyPassword) ?? TCLConfiguration.default.password,
            lines:      defaults.string(forKey: keyLines)      ?? TCLConfiguration.default.lines,
            stops:      defaults.string(forKey: keyStops)      ?? TCLConfiguration.default.stops,
            directions: defaults.string(forKey: keyDirections) ?? TCLConfiguration.default.directions
        )
    }

    func save() {
        let defaults = UserDefaults(suiteName: TCLConfiguration.appGroupID) ?? .standard
        defaults.set(grandLyonBaseURL, forKey: TCLConfiguration.keyGrandLyonBaseURL)
        defaults.set(username, forKey: TCLConfiguration.keyUsername)
        defaults.set(password, forKey: TCLConfiguration.keyPassword)
        defaults.set(lines,      forKey: TCLConfiguration.keyLines)
        defaults.set(stops,      forKey: TCLConfiguration.keyStops)
        defaults.set(directions, forKey: TCLConfiguration.keyDirections)
    }
}
