//
//  BusStopCard.swift
//  buschecker
//

import SwiftUI

struct BusStopCard: View {
    let busStop: BusStop
    let arrivals: [BusService]
    let isLoading: Bool
    let distance: Int? // meters
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "bus.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(.blue, in: Circle())
                
                Text(busStop.Description)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                
                Spacer(minLength: 4)
                
                if let distance = distance {
                    Text("\(distance)m")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Arrivals
            if isLoading && arrivals.isEmpty {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.5)
                    Text("Loading...")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .frame(height: 24)
            } else if arrivals.isEmpty {
                Text("No buses")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .frame(height: 24)
            } else {
                // Show top 3 buses
                HStack(spacing: 8) {
                    ForEach(arrivals.prefix(3)) { service in
                        CompactArrivalBadge(service: service)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

// MARK: - Compact Arrival Badge

struct CompactArrivalBadge: View {
    let service: BusService
    
    private var minutes: String {
        service.NextBus.arrivalText
    }
    
    private var loadColor: Color {
        service.NextBus.loadColor
    }
    
    var body: some View {
        HStack(spacing: 3) {
            // Bus number
            Text(service.ServiceNo)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            // Arrival time
            Text(minutes == "Arr" ? "Arr" : "\(minutes)'")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(minutes == "Arr" ? .green : .secondary)
            
            // Load indicator
            Circle()
                .fill(loadColor)
                .frame(width: 5, height: 5)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color(.systemGray6), in: Capsule())
    }
}

// MARK: - Preview

#Preview {
    let stop = BusStop(
        BusStopCode: "01012",
        RoadName: "Victoria St",
        Description: "Hotel Grand Pacific",
        Latitude: 1.29684825487647,
        Longitude: 103.85253591654006
    )
    
    VStack(spacing: 20) {
        BusStopCard(busStop: stop, arrivals: [], isLoading: true, distance: 120)
        BusStopCard(busStop: stop, arrivals: [], isLoading: false, distance: 250)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}

