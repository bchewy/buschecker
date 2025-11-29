//
//  RootView.swift
//  buschecker
//

import SwiftUI
import Combine

struct RootView: View {
    @StateObject private var appState = AppLoadingState()
    
    var body: some View {
        ZStack {
            // Main content (always loaded, just hidden during launch)
            ContentView()
                .opacity(appState.isReady ? 1 : 0)
            
            // Launch screen overlay
            if !appState.isReady {
                LaunchView(
                    isLoading: $appState.isLoading,
                    loadingStatus: $appState.statusMessage,
                    loadingProgress: $appState.progress
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: appState.isReady)
        .task {
            await appState.initialize()
        }
    }
}

// MARK: - App Loading State

@MainActor
class AppLoadingState: ObservableObject {
    @Published var isLoading = true
    @Published var isReady = false
    @Published var statusMessage = "Starting up..."
    @Published var progress: Double = 0
    
    func initialize() async {
        // Step 1: Initialize
        statusMessage = "Initializing..."
        progress = 0.1
        try? await Task.sleep(for: .milliseconds(300))
        
        // Step 2: Check location permissions
        statusMessage = "Checking location access..."
        progress = 0.2
        try? await Task.sleep(for: .milliseconds(200))
        
        // Step 3: Load bus stops from cache or API
        statusMessage = "Loading bus stops..."
        progress = 0.3
        
        do {
            let stops = try await LTAService.shared.fetchAllBusStops()
            
            // Simulate progress during load
            progress = 0.7
            statusMessage = "Loaded \(stops.count) bus stops"
            try? await Task.sleep(for: .milliseconds(300))
            
        } catch {
            statusMessage = "Using cached data..."
            try? await Task.sleep(for: .milliseconds(300))
        }
        
        // Step 4: Finalize
        progress = 0.9
        statusMessage = "Preparing map..."
        try? await Task.sleep(for: .milliseconds(300))
        
        // Done
        progress = 1.0
        statusMessage = "Ready!"
        isLoading = false
        
        try? await Task.sleep(for: .milliseconds(400))
        
        withAnimation {
            isReady = true
        }
    }
}

#Preview {
    RootView()
}

