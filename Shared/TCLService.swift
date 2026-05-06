import Foundation

actor TCLService {
    static let shared = TCLService()

    // MARK: - Fetch

    func fetchDepartures(configuration: TCLConfiguration) async throws -> TCLData {
        guard let baseURL = URL(string: configuration.serverURL) else {
            throw URLError(.badURL)
        }

        let url = baseURL.appendingPathComponent("/refresh/tcl")
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = TCLRefreshRequest(
            lines: configuration.lines,
            directions: configuration.directions,
            stop_ids: configuration.stops
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let json = try JSONDecoder().decode(TCLResponse.self, from: data)
        return parseResponse(json)
    }

    // MARK: - Parsing

    private func parseResponse(_ response: TCLResponse) -> TCLData {
        var departures: [TCLDeparture] = []

        for (line, stops) in response {
            for (stopName, directions) in stops {
                for (direction, times) in directions {
                    let departure = TCLDeparture(
                        line: line,
                        stopName: stopName,
                        direction: direction,
                        times: times.sorted()
                    )
                    departures.append(departure)
                }
            }
        }

        departures.sort {
            if $0.line != $1.line { return $0.line < $1.line }
            if $0.stopName != $1.stopName { return $0.stopName < $1.stopName }
            return $0.direction < $1.direction
        }

        return TCLData(departures: departures, fetchedAt: Date())
    }
}
