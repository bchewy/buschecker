//
//  PinnedStopsManager.swift
//  buschecker
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PinnedStopsManager: ObservableObject {
    @Published var pinnedStopCodes: [String] = []
    
    private let storageKey = "pinned_bus_stops"
    
    init() {
        load()
    }
    
    func isPinned(_ stopCode: String) -> Bool {
        pinnedStopCodes.contains(stopCode)
    }
    
    func toggle(_ stop: BusStop) {
        if isPinned(stop.BusStopCode) {
            unpin(stop)
        } else {
            pin(stop)
        }
    }
    
    func pin(_ stop: BusStop) {
        guard !isPinned(stop.BusStopCode) else { return }
        pinnedStopCodes.append(stop.BusStopCode)
        save()
    }
    
    func unpin(_ stop: BusStop) {
        pinnedStopCodes.removeAll { $0 == stop.BusStopCode }
        save()
    }
    
    func getPinnedStops(from allStops: [BusStop]) -> [BusStop] {
        pinnedStopCodes.compactMap { code in
            allStops.first { $0.BusStopCode == code }
        }
    }
    
    private func save() {
        UserDefaults.standard.set(pinnedStopCodes, forKey: storageKey)
    }
    
    private func load() {
        pinnedStopCodes = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
    }
}

