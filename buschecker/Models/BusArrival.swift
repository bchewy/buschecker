//
//  BusArrival.swift
//  buschecker
//

import Foundation
import SwiftUI

struct BusArrivalResponse: Codable, Sendable {
    let BusStopCode: String
    let Services: [BusService]
}

struct BusService: Codable, Identifiable, Sendable {
    let ServiceNo: String
    let Operator: String
    let NextBus: NextBusInfo
    let NextBus2: NextBusInfo?
    let NextBus3: NextBusInfo?
    
    var id: String { ServiceNo }
}

struct NextBusInfo: Codable, Sendable {
    let OriginCode: String?
    let DestinationCode: String?
    let EstimatedArrival: String
    let Latitude: String?
    let Longitude: String?
    let VisitNumber: String?
    let Load: String?
    let Feature: String?
    let `Type`: String?
    
    // Computed properties
    var arrivalTime: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: EstimatedArrival) {
            return date
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: EstimatedArrival)
    }
    
    var minutesAway: Int? {
        guard let arrival = arrivalTime else { return nil }
        let minutes = Int(arrival.timeIntervalSinceNow / 60)
        return max(0, minutes)
    }
    
    var arrivalText: String {
        guard let minutes = minutesAway else { return "-" }
        if minutes == 0 { return "Arr" }
        return "\(minutes)"
    }
    
    var loadColor: Color {
        switch Load {
        case "SEA": return .green      // Seats Available
        case "SDA": return .yellow     // Standing Available
        case "LSD": return .red        // Limited Standing
        default: return .gray
        }
    }
    
    var loadDescription: String {
        switch Load {
        case "SEA": return "Seats Available"
        case "SDA": return "Standing Available"
        case "LSD": return "Limited Standing"
        default: return "Unknown"
        }
    }
    
    var busType: String {
        switch `Type` {
        case "SD": return "Single Deck"
        case "DD": return "Double Deck"
        case "BD": return "Bendy"
        default: return ""
        }
    }
    
    var isWheelchairAccessible: Bool {
        Feature == "WAB"
    }
}

