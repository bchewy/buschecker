//
//  LocationManager.swift
//  buschecker
//

import Foundation
import CoreLocation
import MapKit
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let settings = SettingsManager.shared
    
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var error: Error?
    
    // All bus stops loaded from API
    @Published var allBusStops: [BusStop] = []
    
    // Combined stops: nearby + visible on map
    @Published var visibleStops: [BusStop] = []
    
    // Search radius in meters (for nearby)
    @Published var searchRadius: CLLocationDistance = 500
    
    // Current visible map region
    var visibleRegion: MKCoordinateRegion?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50 // Update when moved 50m
        authorizationStatus = locationManager.authorizationStatus
        searchRadius = CLLocationDistance(settings.defaultSearchRadius)
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func centerOnUserLocation() {
        if userLocation != nil {
            objectWillChange.send()
        }
    }
    
    // MARK: - Bus Stop Loading
    
    func loadBusStops() async {
        isLoading = true
        error = nil
        
        do {
            let stops = try await LTAService.shared.fetchAllBusStops()
            allBusStops = stops
            updateVisibleStops()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // MARK: - Visible Region Update
    
    func updateVisibleRegion(_ region: MKCoordinateRegion) {
        visibleRegion = region
        updateVisibleStops()
    }
    
    // MARK: - Combined Stop Filtering
    
    func updateVisibleStops() {
        var combinedStops: [BusStop] = []
        var addedIds = Set<String>()
        
        // 1. First add nearby stops (sorted by distance)
        if let userLocation = userLocation {
            let nearby = allBusStops
                .filter { $0.distance(from: userLocation) <= searchRadius }
                .sorted { $0.distance(from: userLocation) < $1.distance(from: userLocation) }
            
            for stop in nearby {
                if !addedIds.contains(stop.id) {
                    combinedStops.append(stop)
                    addedIds.insert(stop.id)
                }
            }
        }
        
        // 2. Then add stops visible in the map region
        if let region = visibleRegion {
            let inRegion = allBusStops.filter { stop in
                isCoordinate(stop.coordinate, inRegion: region)
            }
            
            // Sort by distance to center of region
            let regionCenter = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
            let sortedInRegion = inRegion.sorted {
                $0.location.distance(from: regionCenter) < $1.location.distance(from: regionCenter)
            }
            
            // Dynamic limit based on zoom level using settings
            let zoomFactor = min(region.span.latitudeDelta, region.span.longitudeDelta)
            let dynamicLimit = settings.maxStops(forZoomSpan: zoomFactor)
            
            for stop in sortedInRegion {
                if !addedIds.contains(stop.id) && combinedStops.count < dynamicLimit {
                    combinedStops.append(stop)
                    addedIds.insert(stop.id)
                }
            }
        }
        
        visibleStops = combinedStops
    }
    
    private func isCoordinate(_ coord: CLLocationCoordinate2D, inRegion region: MKCoordinateRegion) -> Bool {
        let latMin = region.center.latitude - region.span.latitudeDelta / 2
        let latMax = region.center.latitude + region.span.latitudeDelta / 2
        let lonMin = region.center.longitude - region.span.longitudeDelta / 2
        let lonMax = region.center.longitude + region.span.longitudeDelta / 2
        
        return coord.latitude >= latMin && coord.latitude <= latMax &&
               coord.longitude >= lonMin && coord.longitude <= lonMax
    }
    
    func setSearchRadius(_ radius: CLLocationDistance) {
        searchRadius = radius
        updateVisibleStops()
    }
    
    // Convenience for getting just nearby stops
    var nearbyStops: [BusStop] {
        guard let userLocation = userLocation else { return [] }
        return visibleStops.filter { $0.distance(from: userLocation) <= searchRadius }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            self.userLocation = location
            self.updateVisibleStops()
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startUpdatingLocation()
            case .denied, .restricted:
                self.error = LocationError.denied
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = error
        }
    }
}

// MARK: - Location Errors

enum LocationError: LocalizedError {
    case denied
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .denied:
            return "Location access denied. Please enable in Settings."
        case .unknown:
            return "Unknown location error"
        }
    }
}
