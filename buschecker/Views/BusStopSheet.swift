//
//  BusStopSheet.swift
//  buschecker
//

import SwiftUI

struct BusStopSheet: View {
    let busStop: BusStop
    @ObservedObject var pinnedManager: PinnedStopsManager
    
    @State private var services: [BusService] = []
    @State private var isLoading = true
    @State private var error: Error?
    @State private var lastUpdated: Date?
    
    // Auto-refresh timer
    private let refreshInterval: TimeInterval = 20
    @State private var refreshTimer: Timer?
    
    private var isPinned: Bool {
        pinnedManager.isPinned(busStop.BusStopCode)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            if isLoading && services.isEmpty {
                loadingView
            } else if let error = error, services.isEmpty {
                errorView(error)
            } else if services.isEmpty {
                emptyView
            } else {
                servicesList
            }
        }
        .task {
            await fetchArrivals()
            startAutoRefresh()
        }
        .onDisappear {
            stopAutoRefresh()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(busStop.Description)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Pin button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        pinnedManager.toggle(busStop)
                    }
                } label: {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isPinned ? .orange : .secondary)
                        .frame(width: 32, height: 32)
                        .background(isPinned ? Color.orange.opacity(0.15) : Color(.systemGray6))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                // Refresh indicator
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            HStack {
                Text(busStop.RoadName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("•")
                    .foregroundStyle(.tertiary)
                
                Text(busStop.BusStopCode)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            if let lastUpdated = lastUpdated {
                Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
    }
    
    // MARK: - Services List
    
    private var servicesList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(services) { service in
                    BusServiceRow(service: service)
                    
                    if service.id != services.last?.id {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
        }
    }
    
    // MARK: - States
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading arrivals...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            
            Text("Failed to load arrivals")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                Task { await fetchArrivals() }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bus")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text("No buses available")
                .font(.headline)
            
            Text("There are no bus services at this stop right now")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Data Fetching
    
    private func fetchArrivals() async {
        isLoading = true
        
        do {
            let arrivals = try await LTAService.shared.fetchBusArrivals(busStopCode: busStop.BusStopCode)
            services = arrivals.sorted { $0.ServiceNo.localizedStandardCompare($1.ServiceNo) == .orderedAscending }
            lastUpdated = Date()
            error = nil
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // MARK: - Auto Refresh
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
            Task { await fetchArrivals() }
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - Bus Service Row

struct BusServiceRow: View {
    let service: BusService
    
    var body: some View {
        HStack(spacing: 16) {
            // Bus number
            Text(service.ServiceNo)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .frame(width: 50, alignment: .leading)
            
            // Arrival times
            HStack(spacing: 12) {
                ArrivalBadge(busInfo: service.NextBus, isPrimary: true)
                
                if let next2 = service.NextBus2, !next2.EstimatedArrival.isEmpty {
                    ArrivalBadge(busInfo: next2, isPrimary: false)
                }
                
                if let next3 = service.NextBus3, !next3.EstimatedArrival.isEmpty {
                    ArrivalBadge(busInfo: next3, isPrimary: false)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - Arrival Badge

struct ArrivalBadge: View {
    let busInfo: NextBusInfo
    let isPrimary: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            // Time
            Text(busInfo.arrivalText)
                .font(isPrimary ? .system(.title3, design: .rounded, weight: .semibold) : .system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(isPrimary ? .primary : .secondary)
            
            // Minutes label
            if busInfo.arrivalText != "Arr" && busInfo.arrivalText != "-" {
                Text("min")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            // Load indicator
            Circle()
                .fill(busInfo.loadColor)
                .frame(width: 8, height: 8)
            
            // Bus type icons
            HStack(spacing: 2) {
                if busInfo.isWheelchairAccessible {
                    Image(systemName: "figure.roll")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
                
                if busInfo.Type == "DD" {
                    Image(systemName: "bus.doubledecker")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(minWidth: isPrimary ? 50 : 40)
    }
}
