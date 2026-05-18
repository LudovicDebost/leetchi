import Foundation

actor TCLService {
    static let shared = TCLService()

    func fetchDepartures(configuration: TCLConfiguration) async throws -> TCLData {
        let lines = csvValues(configuration.lines)
        let directions = csvValues(configuration.directions)
        let stopIDs = csvValues(configuration.stops)

        let passagesURL = try makePassagesURL(
            baseURLString: configuration.grandLyonBaseURL,
            lines: lines,
            directions: directions,
            stopIDs: stopIDs
        )
        let stopsURL = try makeStopsURL(baseURLString: configuration.grandLyonBaseURL, stopIDs: stopIDs)

        async let passagesResponse: GrandLyonResponse<GrandLyonPassage> = requestJSON(
            url: passagesURL,
            username: configuration.username,
            password: configuration.password
        )
        async let stopsResponse: GrandLyonResponse<GrandLyonStop> = requestJSON(
            url: stopsURL,
            username: configuration.username,
            password: configuration.password
        )

        let (passages, stops) = try await (passagesResponse, stopsResponse)
        return parseResponse(passages: passages.values, stops: stops.values)
    }

    // MARK: - HTTP

    private func requestJSON<T: Decodable>(url: URL, username: String, password: String) async throws -> T {
        var request = URLRequest(url: url, timeoutInterval: 20)

        if !username.isEmpty || !password.isEmpty {
            let raw = "\(username):\(password)"
            if let data = raw.data(using: .utf8) {
                request.setValue("Basic \(data.base64EncodedString())", forHTTPHeaderField: "Authorization")
            }
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - URL building

    private func makePassagesURL(baseURLString: String, lines: [String], directions: [String], stopIDs: [String]) throws -> URL {
        guard let baseURL = URL(string: baseURLString) else { throw URLError(.badURL) }
        let endpointURL = baseURL.appendingPathComponent("tcl_sytral.tclpassagearret/all.json")
        guard var components = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        var queryItems: [URLQueryItem] = []
        if !lines.isEmpty {
            queryItems.append(URLQueryItem(name: "ligne__in", value: lines.joined(separator: ",")))
        }
        if !directions.isEmpty {
            queryItems.append(URLQueryItem(name: "idtarretdestination__in", value: directions.joined(separator: ",")))
        }
        if !stopIDs.isEmpty {
            queryItems.append(URLQueryItem(name: "id__in", value: stopIDs.joined(separator: ",")))
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else { throw URLError(.badURL) }
        return url
    }

    private func makeStopsURL(baseURLString: String, stopIDs: [String]) throws -> URL {
        guard let baseURL = URL(string: baseURLString) else { throw URLError(.badURL) }
        let endpointURL = baseURL.appendingPathComponent("tcl_sytral.tclarret/all.json")
        guard var components = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        if !stopIDs.isEmpty {
            components.queryItems = [URLQueryItem(name: "id__in", value: stopIDs.joined(separator: ","))]
        }

        guard let url = components.url else { throw URLError(.badURL) }
        return url
    }

    private func csvValues(_ raw: String) -> [String] {
        raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Parsing

    private func parseResponse(passages: [GrandLyonPassage], stops: [GrandLyonStop]) -> TCLData {
        var departures: [TCLDeparture] = []
        var stopNamesByID: [String: String] = [:]

        for stop in stops {
            stopNamesByID[stop.id] = stop.nom
        }

        var groupedTimes: [String: [String]] = [:]

        for passage in passages {
            let line = passage.ligne
            let stopName = stopNamesByID[passage.id] ?? passage.id
            let direction = passage.direction
            let key = "\(line)|\(stopName)|\(direction)"
            groupedTimes[key, default: []].append(passage.heurepassage)
        }

        for (key, times) in groupedTimes {
            let parts = key.split(separator: "|", maxSplits: 2).map(String.init)
            guard parts.count == 3 else { continue }
            departures.append(
                TCLDeparture(
                    line: parts[0],
                    stopName: parts[1],
                    direction: parts[2],
                    times: times.sorted()
                )
            )
        }

        departures.sort {
            if $0.line != $1.line { return $0.line < $1.line }
            if $0.stopName != $1.stopName { return $0.stopName < $1.stopName }
            return $0.direction < $1.direction
        }

        return TCLData(departures: departures, fetchedAt: Date())
    }
}
