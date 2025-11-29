//
//  LaunchView.swift
//  buschecker
//

import SwiftUI

struct LaunchView: View {
    @Binding var isLoading: Bool
    @Binding var loadingStatus: String
    @Binding var loadingProgress: Double
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.15, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // App icon / logo
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .blue.opacity(0.5), radius: 20, y: 10)
                    
                    Image(systemName: "bus.fill")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                // App name
                VStack(spacing: 4) {
                    Text("BusChecker")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Singapore")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Loading section
                VStack(spacing: 16) {
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * loadingProgress, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: loadingProgress)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 50)
                    
                    // Status text
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        
                        Text(loadingStatus)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .animation(.easeInOut, value: loadingStatus)
                }
                .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    LaunchView(
        isLoading: .constant(true),
        loadingStatus: .constant("Loading bus stops..."),
        loadingProgress: .constant(0.6)
    )
}

