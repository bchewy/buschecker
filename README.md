# 🚌 BusCheckerSG

A native iOS app for checking real-time bus arrival times in Singapore, built with SwiftUI.

![iOS 17+](https://img.shields.io/badge/iOS-17+-blue)
![Swift 6](https://img.shields.io/badge/Swift-6-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- 🗺️ **Interactive Map** — View all bus stops on an Apple Maps-powered interface
- 📍 **Nearby Stops** — Automatically find bus stops within your configurable radius (250m–2km)
- ⏱️ **Real-time Arrivals** — Live bus arrival times with auto-refresh (10s–60s intervals)
- 📌 **Pinned Stops** — Save your frequently used stops for quick access
- 🔍 **Search** — Find any bus stop across Singapore
- ♿ **Accessibility Info** — See wheelchair-accessible buses at a glance
- 🚌 **Bus Details** — View bus type (single/double-decker) and crowd levels

## Screenshots

<!-- Add your screenshots here -->

## Requirements

- iOS 17.0+
- Xcode 16+
- LTA DataMall API Key ([Request here](https://datamall.lta.gov.sg/content/datamall/en/request-for-api.html))

## Setup

1. Clone the repo
   ```bash
   git clone https://github.com/yourusername/buschecker.git
   cd buschecker
   ```

2. Create your config file
   ```bash
   cp buschecker/Config.example.swift buschecker/Config.swift
   ```

3. Add your LTA API key to `buschecker/Config.swift`:
   ```swift
   let ltaApiKey = "YOUR_LTA_API_KEY_HERE"
   ```

4. Open `buschecker.xcodeproj` in Xcode and run

## Project Structure

```
buschecker/
├── Models/
│   ├── BusStop.swift         # Bus stop data model
│   └── BusArrival.swift      # Bus arrival data model
├── Services/
│   ├── LTAService.swift      # LTA DataMall API client
│   ├── LocationManager.swift # Core Location handling
│   ├── ArrivalsManager.swift # Real-time arrivals management
│   └── PinnedStopsManager.swift
├── Views/
│   ├── BusStopCard.swift     # Carousel card component
│   ├── BusStopSheet.swift    # Stop detail sheet
│   ├── SettingsView.swift    # App settings
│   └── StopsListView.swift   # Searchable stops list
└── ContentView.swift         # Main map view
```

## API

This app uses the [LTA DataMall API](https://datamall.lta.gov.sg/content/datamall/en.html):

- **Bus Stops** — `/BusStops` — All ~5,000 bus stops in Singapore (cached locally)
- **Bus Arrivals** — `/v3/BusArrival` — Real-time arrival predictions

## Privacy

- **Location**: Used only to find nearby bus stops. Never stored or transmitted.
- **No tracking**: No analytics or third-party SDKs.
- **Local storage**: Pinned stops and settings stored on-device only.

## License

MIT

## Acknowledgments

- Bus data provided by [Land Transport Authority (LTA)](https://datamall.lta.gov.sg/)
