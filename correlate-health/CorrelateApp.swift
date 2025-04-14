//
//  CorrelateApp.swift
//  Correlate
//
//  Created by Blake Rayvid on 4/12/25.
//
import SwiftUI
import HealthKit

@main
struct CorrelateApp: App {
    @StateObject private var healthManager = HealthManager()

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Dashboard", systemImage: "house")
                    }

                InsightsView()
                    .tabItem {
                        Label("Insights", systemImage: "lightbulb")
                    }

                CorrelationView()
                    .tabItem {
                        Label("Correlate", systemImage: "chart.xyaxis.line")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .environmentObject(healthManager)
            .onAppear {
                healthManager.requestAuthorization()
            }
        }
    }
}
