//
//  SettingsManager.swift
//  buschecker
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // MARK: - Published Settings
    
    @AppStorage("maxStopsZoomedIn") var maxStopsZoomedIn: Int = 50
    @AppStorage("maxStopsMediumZoom") var maxStopsMediumZoom: Int = 30
    @AppStorage("maxStopsZoomedOut") var maxStopsZoomedOut: Int = 15
    @AppStorage("defaultSearchRadius") var defaultSearchRadius: Int = 500
    @AppStorage("arrivalRefreshInterval") var arrivalRefreshInterval: Int = 20
    @AppStorage("showWheelchairAccessible") var showWheelchairAccessible: Bool = true
    @AppStorage("showBusType") var showBusType: Bool = true
    @AppStorage("showLoadIndicator") var showLoadIndicator: Bool = true
    @AppStorage("showBusStopCarousel") var showBusStopCarousel: Bool = false
    @AppStorage("pinnedStopColorName") var pinnedStopColorName: String = "orange"
    
    // Computed property for the actual Color
    var pinnedStopColor: Color {
        Self.colorOptions[pinnedStopColorName] ?? .orange
    }
    
    static let colorOptions: [String: Color] = [
        "orange": .orange,
        "red": .red,
        "pink": .pink,
        "purple": .purple,
        "blue": .blue,
        "teal": .teal,
        "green": .green,
        "yellow": .yellow
    ]
    
    private init() {}
    
    // MARK: - Helpers
    
    func maxStops(forZoomSpan span: Double) -> Int {
        if span < 0.01 {
            return maxStopsZoomedIn
        } else if span < 0.05 {
            return maxStopsMediumZoom
        } else {
            return maxStopsZoomedOut
        }
    }
    
    func resetToDefaults() {
        maxStopsZoomedIn = 50
        maxStopsMediumZoom = 30
        maxStopsZoomedOut = 15
        defaultSearchRadius = 500
        arrivalRefreshInterval = 20
        showWheelchairAccessible = true
        showBusType = true
        showLoadIndicator = true
        showBusStopCarousel = false
        pinnedStopColorName = "orange"
    }
}

