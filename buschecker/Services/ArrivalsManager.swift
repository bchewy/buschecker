//
//  ArrivalsManager.swift
//  buschecker
//

import Foundation
import Combine

@MainActor
class ArrivalsManager: ObservableObject {
    @Published var arrivals: [String: [BusService]] = [:] // stopCode -> arrivals
    @Published var loadingStops: Set<String> = []
    
    private var refreshTask: Task<Void, Never>?
    private let refreshInterval: TimeInterval = 20
    
    // Fetch arrivals for multiple stops
    func fetchArrivals(for stops: [BusStop]) {
        // Cancel previous refresh task
        refreshTask?.cancel()
        
        // Start fetching for each stop
        for stop in stops.prefix(8) { // Limit to 8 nearest stops
            if !loadingStops.contains(stop.BusStopCode) {
                fetchArrival(for: stop.BusStopCode)
            }
        }
        
        // Start auto-refresh
        startAutoRefresh(for: stops)
    }
    
    private func fetchArrival(for stopCode: String) {
        loadingStops.insert(stopCode)
        
        Task {
            do {
                let services = try await LTAService.shared.fetchBusArrivals(busStopCode: stopCode)
                arrivals[stopCode] = services.sorted {
                    $0.ServiceNo.localizedStandardCompare($1.ServiceNo) == .orderedAscending
                }
            } catch {
                // Keep old data on error, or set empty
                if arrivals[stopCode] == nil {
                    arrivals[stopCode] = []
                }
            }
            loadingStops.remove(stopCode)
        }
    }
    
    private func startAutoRefresh(for stops: [BusStop]) {
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(refreshInterval))
                
                guard !Task.isCancelled else { break }
                
                // Refresh all visible stops
                for stop in stops.prefix(8) {
                    fetchArrival(for: stop.BusStopCode)
                }
            }
        }
    }
    
    func stopRefreshing() {
        refreshTask?.cancel()
        refreshTask = nil
    }
    
    func getArrivals(for stopCode: String) -> [BusService] {
        arrivals[stopCode] ?? []
    }
    
    func isLoading(stopCode: String) -> Bool {
        loadingStops.contains(stopCode)
    }
}

