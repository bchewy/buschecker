//
//  ContentView.swift
//  buschecker
//

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var arrivalsManager = ArrivalsManager()
    @StateObject private var pinnedManager = PinnedStopsManager()
    @ObservedObject private var settings = SettingsManager.shared
    
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var showingLocationSettings = false
    @State private var showingAppSettings = false
    @State private var selectedStop: BusStop?
    @State private var showingSheet = false
    @State private var selectedStopID: String?
    @State private var showingPinnedList = false
    @State private var showingStopsList = false
    
    // Singapore center
    private let singaporeCenter = CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)
    
    private var pinnedStops: [BusStop] {
        pinnedManager.getPinnedStops(from: locationManager.allBusStops)
    }
    
    var body: some View {
        ZStack {
            // Map
            mapView
            
            // Floating cards overlay
            VStack(spacing: 0) {
                // Top status bar
                topBar
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                Spacer()
                
                // Bus stop cards at bottom (only nearby stops)
                if settings.showBusStopCarousel && !locationManager.nearbyStops.isEmpty {
                    stopsCarousel
                }
                
                // Bottom controls
                bottomControls
            }
        }
        .task {
            await initialize()
        }
        .onChange(of: locationManager.nearbyStops) { _, newStops in
            arrivalsManager.fetchArrivals(for: newStops)
        }
        .onChange(of: locationManager.userLocation) { oldValue, newValue in
            if oldValue == nil, let location = newValue {
                withAnimation {
                    mapPosition = .region(MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                    ))
                }
            }
        }
        .onChange(of: selectedStopID) { _, newValue in
            if let stopID = newValue,
               let stop = locationManager.visibleStops.first(where: { $0.id == stopID }) {
                selectedStop = stop
                showingSheet = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedStopID = nil
                }
            }
        }
        .sheet(isPresented: $showingSheet) {
            if let stop = selectedStop {
                BusStopSheet(busStop: stop, pinnedManager: pinnedManager)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showingPinnedList) {
            PinnedStopsListView(
                pinnedStops: pinnedStops,
                pinnedManager: pinnedManager,
                onSelectStop: { stop in
                    showingPinnedList = false
                    selectedStop = stop
                    showingSheet = true
                    centerOnStop(stop)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAppSettings) {
            SettingsView(settings: settings)
        }
        .sheet(isPresented: $showingStopsList) {
            StopsListView(
                nearbyStops: locationManager.nearbyStops,
                allStops: locationManager.allBusStops,
                userLocation: locationManager.userLocation,
                onSelectStop: { stop in
                    showingStopsList = false
                    selectedStop = stop
                    showingSheet = true
                    centerOnStop(stop)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Location Access Required", isPresented: $showingLocationSettings) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable location access in Settings to find nearby bus stops.")
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        Map(position: $mapPosition, selection: $selectedStopID) {
            // User location
            UserAnnotation()
            
            // Pinned stops (orange markers)
            ForEach(pinnedStops) { stop in
                Annotation(stop.Description, coordinate: stop.coordinate, anchor: .center) {
                    PinnedStopMarker(color: settings.pinnedStopColor)
                }
                .tag(stop.id)
            }
            
            // Regular bus stop markers (blue)
            ForEach(locationManager.visibleStops.filter { !pinnedManager.isPinned($0.BusStopCode) }) { stop in
                Annotation(stop.Description, coordinate: stop.coordinate, anchor: .center) {
                    BusStopMarker()
                }
                .tag(stop.id)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls {
            MapCompass()
        }
        .ignoresSafeArea()
        .onMapCameraChange(frequency: .onEnd) { context in
            locationManager.updateVisibleRegion(context.region)
        }
        .onAppear {
            mapPosition = .region(MKCoordinateRegion(
                center: singaporeCenter,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
    
    // MARK: - Stops Carousel (only nearby stops)
    
    private var stopsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(locationManager.nearbyStops.prefix(8)) { stop in
                    BusStopCard(
                        busStop: stop,
                        arrivals: arrivalsManager.getArrivals(for: stop.BusStopCode),
                        isLoading: arrivalsManager.isLoading(stopCode: stop.BusStopCode),
                        distance: distanceToStop(stop)
                    )
                    .frame(width: 200)
                    .onTapGesture {
                        selectedStop = stop
                        showingSheet = true
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.03)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            if locationManager.isLoading {
                loadingPill
            } else if let error = locationManager.error {
                errorPill(error)
            }
            
            Spacer()
        }
    }
    
    private var loadingPill: some View {
        HStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.7)
            Text("Loading stops...")
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
    
    @ObservedObject private var refreshTimer = RefreshTimerManager.shared
    
    private var statusPill: some View {
        Button {
            showingStopsList = true
        } label: {
            HStack(spacing: 6) {
                if refreshTimer.justUpdated {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.green)
                    
                    Text("Updated!")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11, weight: .medium))
                    
                    Text("Search")
                        .font(.system(size: 12, weight: .medium))
                    
                    Text("•")
                        .foregroundStyle(.tertiary)
                    
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9, weight: .medium))
                        Text("\(refreshTimer.countdown)s")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(refreshTimer.justUpdated ? Color.green.opacity(0.15) : Color.clear)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .animation(.easeInOut(duration: 0.3), value: refreshTimer.justUpdated)
        }
        .buttonStyle(.plain)
        .overlay {
            if refreshTimer.justUpdated {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
    }
    
    private func errorPill(_ error: Error) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 10))
            Text(error.localizedDescription)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .onTapGesture {
            if error is LocationError {
                showingLocationSettings = true
            }
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        HStack(alignment: .bottom) {
            // Left controls
            VStack(alignment: .leading, spacing: 8) {
                // Settings button
                Button {
                    showingAppSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                
                // Pinned stops button
                Button {
                    showingPinnedList = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 14, weight: .medium))
                        
                        if !pinnedStops.isEmpty {
                            Text("\(pinnedStops.count)")
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .foregroundColor(pinnedStops.isEmpty ? .secondary : settings.pinnedStopColor)
                    .frame(height: 40)
                    .padding(.horizontal, 14)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 12)
            .padding(.bottom, 8)
            
            Spacer()
            
            // Center status pill
            if !locationManager.visibleStops.isEmpty {
                statusPill
                    .padding(.bottom, 8)
            }
            
            Spacer()
            
            VStack(spacing: 10) {
                // Locate me button
                Button {
                    centerOnUser()
                } label: {
                    Image(systemName: locationManager.userLocation != nil ? "location.fill" : "location")
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                
                // Radius control (for nearby filtering)
                Menu {
                    ForEach([250, 500, 1000, 2000], id: \.self) { radius in
                        Button {
                            locationManager.setSearchRadius(Double(radius))
                        } label: {
                            HStack {
                                Text("\(radius)m")
                                if Int(locationManager.searchRadius) == radius {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text("\(Int(locationManager.searchRadius))m")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 44, height: 28)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 12)
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Helpers
    
    private func centerOnUser() {
        if let location = locationManager.userLocation {
            withAnimation {
                mapPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                ))
            }
        }
    }
    
    private func centerOnStop(_ stop: BusStop) {
        withAnimation {
            mapPosition = .region(MKCoordinateRegion(
                center: stop.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
    }
    
    private func distanceToStop(_ stop: BusStop) -> Int? {
        guard let userLocation = locationManager.userLocation else { return nil }
        return Int(stop.distance(from: userLocation))
    }
    
    private func initialize() async {
        locationManager.requestPermission()
        await locationManager.loadBusStops()
    }
}

// MARK: - Bus Stop Marker (Blue)

struct BusStopMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 32, height: 32)
                .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
            
            Image(systemName: "bus.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.blue)
        }
    }
}

// MARK: - Pinned Stop Marker

struct PinnedStopMarker: View {
    var color: Color = .orange
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 36, height: 36)
                .shadow(color: color.opacity(0.4), radius: 4, y: 2)
            
            Image(systemName: "bus.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Pinned Stops List View

struct PinnedStopsListView: View {
    let pinnedStops: [BusStop]
    @ObservedObject var pinnedManager: PinnedStopsManager
    let onSelectStop: (BusStop) -> Void
    
    var body: some View {
        NavigationStack {
            Group {
                if pinnedStops.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(pinnedStops) { stop in
                            Button {
                                onSelectStop(stop)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "pin.fill")
                                        .foregroundStyle(SettingsManager.shared.pinnedStopColor)
                                        .font(.system(size: 14))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(stop.Description)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(.primary)
                                        
                                        Text("\(stop.RoadName) • \(stop.BusStopCode)")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 4)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    pinnedManager.unpin(stop)
                                } label: {
                                    Label("Unpin", systemImage: "pin.slash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Pinned Stops")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pin.slash")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("No Pinned Stops")
                .font(.headline)
            
            Text("Tap the pin icon on any bus stop to save it here for quick access.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Text(particle.emoji)
                        .font(.system(size: particle.size))
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geo.size)
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        let emojis = ["🎉", "✨", "🚌", "⭐️", "🎊"]
        
        for i in 0..<12 {
            let particle = ConfettiParticle(
                emoji: emojis.randomElement()!,
                size: CGFloat.random(in: 12...20),
                position: CGPoint(
                    x: CGFloat.random(in: -50...size.width + 50),
                    y: CGFloat.random(in: -30...0)
                ),
                opacity: 1.0
            )
            particles.append(particle)
            
            // Animate each particle
            let delay = Double(i) * 0.05
            withAnimation(.easeOut(duration: 1.5).delay(delay)) {
                if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                    particles[index].position.y += CGFloat.random(in: 80...150)
                    particles[index].position.x += CGFloat.random(in: -30...30)
                    particles[index].opacity = 0
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let emoji: String
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

#Preview {
    ContentView()
}
