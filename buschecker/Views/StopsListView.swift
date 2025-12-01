//
//  StopsListView.swift
//  buschecker
//

import SwiftUI
import CoreLocation

struct StopsListView: View {
    let nearbyStops: [BusStop]
    let allStops: [BusStop]
    let userLocation: CLLocation?
    let onSelectStop: (BusStop) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredStops: [BusStop] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return allStops.filter { stop in
            stop.Description.lowercased().contains(query) ||
            stop.RoadName.lowercased().contains(query) ||
            stop.BusStopCode.lowercased().contains(query)
        }
        .prefix(50)
        .sorted { stop1, stop2 in
            // Sort by distance if user location available
            guard let location = userLocation else { return false }
            let dist1 = location.distance(from: CLLocation(latitude: stop1.Latitude, longitude: stop1.Longitude))
            let dist2 = location.distance(from: CLLocation(latitude: stop2.Latitude, longitude: stop2.Longitude))
            return dist1 < dist2
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search all bus stops...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
                
                if searchText.isEmpty {
                    // Stats header
                    statsHeader
                    
                    // Nearby stops list
                    if !nearbyStops.isEmpty {
                        Text("\(nearbyStops.count) nearby stops")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                    
                    stopsList(nearbyStops)
                } else {
                    // Search results
                    searchResultsList
                }
            }
            .navigationTitle("Bus Stops")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var statsHeader: some View {
        HStack(spacing: 16) {
            StatBox(title: "Total", value: "\(allStops.count)", subtitle: "in Singapore")
            StatBox(title: "Nearby", value: "\(nearbyStops.count)", subtitle: "within radius")
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var searchResultsList: some View {
        Group {
            if filteredStops.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No bus stops match \"\(searchText)\"")
                )
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(filteredStops.count) results")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    stopsList(Array(filteredStops))
                }
            }
        }
    }
    
    private func stopsList(_ stops: [BusStop]) -> some View {
        Group {
            if stops.isEmpty {
                ContentUnavailableView(
                    "No Stops",
                    systemImage: "bus",
                    description: Text("No bus stops in this category")
                )
            } else {
                List(stops) { stop in
                    Button {
                        onSelectStop(stop)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(stop.Description)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                HStack(spacing: 8) {
                                    Text(stop.RoadName)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(stop.BusStopCode)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(.systemGray5))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                            
                            Spacer()
                            
                            if let distance = distanceText(to: stop) {
                                Text(distance)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
    }
    
    private func distanceText(to stop: BusStop) -> String? {
        guard let userLocation = userLocation else { return nil }
        let stopLocation = CLLocation(latitude: stop.Latitude, longitude: stop.Longitude)
        let distance = userLocation.distance(from: stopLocation)
        
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    StopsListView(
        nearbyStops: [],
        allStops: [],
        userLocation: nil,
        onSelectStop: { _ in }
    )
}
