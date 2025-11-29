//
//  LTAService.swift
//  buschecker
//

import Foundation

actor LTAService {
    static let shared = LTAService()
    
    private let baseURL = "https://datamall2.mytransport.sg/ltaodataservice"
    private var cachedStops: [BusStop] = []
    private var lastFetchDate: Date?
    
    private init() {}
    
    // MARK: - Bus Stops
    
    /// Fetches all bus stops from LTA API (paginated)
    /// Returns cached data if available and less than 24 hours old
    func fetchAllBusStops(forceRefresh: Bool = false) async throws -> [BusStop] {
        // Return cached data if valid
        if !forceRefresh,
           !cachedStops.isEmpty,
           let lastFetch = lastFetchDate,
           Date().timeIntervalSince(lastFetch) < 86400 { // 24 hours
            return cachedStops
        }
        
        // Try loading from disk cache first
        if !forceRefresh, let diskCache = loadBusStopsFromDisk() {
            cachedStops = diskCache
            lastFetchDate = Date()
            return cachedStops
        }
        
        // Fetch from API (paginated, 500 per page)
        var allStops: [BusStop] = []
        var skip = 0
        let pageSize = 500
        
        while true {
            let stops = try await fetchBusStopsPage(skip: skip)
            allStops.append(contentsOf: stops)
            
            if stops.count < pageSize {
                break
            }
            skip += pageSize
        }
        
        cachedStops = allStops
        lastFetchDate = Date()
        
        // Save to disk
        saveBusStopsToDisk(allStops)
        
        return allStops
    }
    
    private func fetchBusStopsPage(skip: Int) async throws -> [BusStop] {
        var components = URLComponents(string: "\(baseURL)/BusStops")!
        components.queryItems = [URLQueryItem(name: "$skip", value: "\(skip)")]
        
        guard let url = components.url else {
            throw LTAError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(ltaApiKey, forHTTPHeaderField: "AccountKey")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LTAError.invalidResponse(statusCode: nil, body: nil)
        }
        
        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8)
            throw LTAError.invalidResponse(statusCode: httpResponse.statusCode, body: body)
        }
        
        return try decodeBusStopsResponse(from: data)
    }
    
    // MARK: - Bus Arrivals
    
    /// Fetches real-time bus arrivals for a specific bus stop
    func fetchBusArrivals(busStopCode: String) async throws -> [BusService] {
        var components = URLComponents(string: "\(baseURL)/v3/BusArrival")!
        components.queryItems = [URLQueryItem(name: "BusStopCode", value: busStopCode)]
        
        guard let url = components.url else {
            throw LTAError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(ltaApiKey, forHTTPHeaderField: "AccountKey")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LTAError.invalidResponse(statusCode: nil, body: nil)
        }
        
        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8)
            throw LTAError.invalidResponse(statusCode: httpResponse.statusCode, body: body)
        }
        
        return try decodeBusArrivalResponse(from: data)
    }
    
    // MARK: - Disk Cache
    
    private nonisolated var cacheFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("bus_stops_cache.json")
    }
    
    private func saveBusStopsToDisk(_ stops: [BusStop]) {
        do {
            let data = try JSONEncoder().encode(stops)
            try data.write(to: cacheFileURL)
        } catch {
            print("Failed to save bus stops to disk: \(error)")
        }
    }
    
    private func loadBusStopsFromDisk() -> [BusStop]? {
        do {
            let data = try Data(contentsOf: cacheFileURL)
            return try JSONDecoder().decode([BusStop].self, from: data)
        } catch {
            return nil
        }
    }
}

// MARK: - Nonisolated Decoders (Swift 6 compatibility)

private func decodeBusStopsResponse(from data: Data) throws -> [BusStop] {
    let decoded = try JSONDecoder().decode(BusStopsResponse.self, from: data)
    return decoded.value
}

private func decodeBusArrivalResponse(from data: Data) throws -> [BusService] {
    let decoded = try JSONDecoder().decode(BusArrivalResponse.self, from: data)
    return decoded.Services
}

// MARK: - Errors

enum LTAError: LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int?, body: String?)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse(let statusCode, _):
            if let code = statusCode {
                return "Server error (\(code))"
            }
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
