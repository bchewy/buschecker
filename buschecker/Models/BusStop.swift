//
//  BusStop.swift
//  buschecker
//

import Foundation
import CoreLocation

struct BusStop: Codable, Identifiable, Hashable, Sendable {
    let BusStopCode: String
    let RoadName: String
    let Description: String
    let Latitude: Double
    let Longitude: Double
    
    var id: String { BusStopCode }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: Latitude, longitude: Longitude)
    }
    
    var location: CLLocation {
        CLLocation(latitude: Latitude, longitude: Longitude)
    }
    
    func distance(from userLocation: CLLocation) -> CLLocationDistance {
        location.distance(from: userLocation)
    }
}

// MARK: - LTA API Response
struct BusStopsResponse: Codable, Sendable {
    let value: [BusStop]
}

