//
//  RefreshTimerManager.swift
//  buschecker
//

import Foundation
import Combine

@MainActor
class RefreshTimerManager: ObservableObject {
    static let shared = RefreshTimerManager()
    
    @Published var countdown: Int = 0
    @Published var justUpdated: Bool = false
    
    private var timer: Timer?
    
    private init() {
        startTimer()
    }
    
    func startTimer() {
        countdown = SettingsManager.shared.arrivalRefreshInterval
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    private func tick() {
        if countdown > 0 {
            countdown -= 1
        } else {
            // Trigger update
            justUpdated = true
            
            // Post notification for any listeners to refresh their data
            NotificationCenter.default.post(name: .refreshTriggered, object: nil)
            
            // Reset after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.justUpdated = false
                self?.countdown = SettingsManager.shared.arrivalRefreshInterval
            }
        }
    }
    
    func resetCountdown() {
        countdown = SettingsManager.shared.arrivalRefreshInterval
    }
}

extension Notification.Name {
    static let refreshTriggered = Notification.Name("refreshTriggered")
}

