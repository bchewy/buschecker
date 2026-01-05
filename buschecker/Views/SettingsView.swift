//
//  SettingsView.swift
//  buschecker
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                // Map Settings
                Section {
                    StepperRow(
                        title: "Zoomed In",
                        subtitle: "Street level view",
                        value: $settings.maxStopsZoomedIn,
                        range: 10...100,
                        step: 10
                    )
                    
                    StepperRow(
                        title: "Medium Zoom",
                        subtitle: "Neighborhood view",
                        value: $settings.maxStopsMediumZoom,
                        range: 10...50,
                        step: 5
                    )
                    
                    StepperRow(
                        title: "Zoomed Out",
                        subtitle: "City view",
                        value: $settings.maxStopsZoomedOut,
                        range: 5...30,
                        step: 5
                    )
                } header: {
                    Text("Max Stops on Map")
                } footer: {
                    Text("Controls how many bus stops appear on the map at different zoom levels.")
                }
                
                // Search Settings
                Section {
                    Picker("Default Radius", selection: $settings.defaultSearchRadius) {
                        Text("250m").tag(250)
                        Text("500m").tag(500)
                        Text("1km").tag(1000)
                        Text("2km").tag(2000)
                    }
                } header: {
                    Text("Nearby Stops")
                } footer: {
                    Text("Default search radius for finding nearby bus stops.")
                }
                
                // Refresh Settings
                Section {
                    Picker("Refresh Interval", selection: $settings.arrivalRefreshInterval) {
                        Text("10 seconds").tag(10)
                        Text("20 seconds").tag(20)
                        Text("30 seconds").tag(30)
                        Text("1 minute").tag(60)
                    }
                } header: {
                    Text("Bus Arrivals")
                } footer: {
                    Text("How often to refresh bus arrival times.")
                }
                
                // Display Settings
                Section {
                    Toggle("Bus Stop Carousel", isOn: $settings.showBusStopCarousel)
                    Toggle("Wheelchair Accessible", isOn: $settings.showWheelchairAccessible)
                    Toggle("Bus Type (SD/DD)", isOn: $settings.showBusType)
                    Toggle("Load Indicator", isOn: $settings.showLoadIndicator)
                } header: {
                    Text("Display Options")
                } footer: {
                    Text("Carousel shows nearby bus stops with arrival times at the bottom of the map.")
                }
                
                // Pinned Stops Color
                Section {
                    HStack {
                        Text("Pinned Stop Color")
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(Array(SettingsManager.colorOptions.keys.sorted()), id: \.self) { colorName in
                                Button {
                                    settings.pinnedStopColorName = colorName
                                } label: {
                                    Circle()
                                        .fill(SettingsManager.colorOptions[colorName] ?? .orange)
                                        .frame(width: 28, height: 28)
                                        .overlay {
                                            if settings.pinnedStopColorName == colorName {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } header: {
                    Text("Pinned Stops")
                }
                
                // Reset
                Section {
                    Button(role: .destructive) {
                        settings.resetToDefaults()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset to Defaults")
                            Spacer()
                        }
                    }
                }
                
                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Data Source")
                        Spacer()
                        Text("LTA DataMall")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
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
}

// MARK: - Stepper Row

struct StepperRow: View {
    let title: String
    let subtitle: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button {
                    if value - step >= range.lowerBound {
                        value -= step
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value <= range.lowerBound ? .gray : .blue)
                }
                .buttonStyle(.plain)
                .disabled(value <= range.lowerBound)
                
                Text("\(value)")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .frame(minWidth: 36)
                
                Button {
                    if value + step <= range.upperBound {
                        value += step
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value >= range.upperBound ? .gray : .blue)
                }
                .buttonStyle(.plain)
                .disabled(value >= range.upperBound)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView(settings: SettingsManager.shared)
}

