//
//  ContentView.swift
//  Correlate
//
//  Created by Blake Rayvid on 4/12/25.
//
import SwiftUI
import HealthKit

struct ContentView: View {
    @EnvironmentObject var healthManager: HealthManager

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Activity")) {
                    NavigationLink(destination: MetricGraphView(title: "Steps", samples: healthManager.steps)) {
                        Text("Step Count")
                    }
                    NavigationLink(destination: MetricGraphView(title: "Active Energy", samples: healthManager.activeEnergy)) {
                        Text("Active Energy")
                    }
                }

                Section(header: Text("Nutrition")) {
                    NavigationLink(destination: MetricGraphView(title: "Dietary Energy", samples: healthManager.dietaryEnergy)) {
                        Text("Dietary Energy")
                    }
                    NavigationLink(destination: MetricGraphView(title: "Protein", samples: healthManager.protein)) {
                        Text("Dietary Protein")
                    }
                    NavigationLink(destination: MetricGraphView(title: "Fat", samples: healthManager.fat)) {
                        Text("Dietary Fat")
                    }
                    NavigationLink(destination: MetricGraphView(title: "Carbohydrates", samples: healthManager.carbohydrates)) {
                        Text("Dietary Carbohydrates")
                    }
                }

                Section(header: Text("Vitals")) {
                    NavigationLink(destination: MetricGraphView(title: "Heart Rate", samples: healthManager.heartRate)) {
                        Text("Heart Rate")
                    }
                    NavigationLink(destination: MetricGraphView(title: "HRV", samples: healthManager.hrv)) {
                        Text("Heart Rate Variability (HRV)")
                    }
                }

                Section(header: Text("Body Measurements")) {
                    NavigationLink(destination: MetricGraphView(title: "Body Mass", samples: healthManager.bodyMass)) {
                        Text("Body Mass")
                    }
                    NavigationLink(destination: MetricGraphView(title: "BMI", samples: healthManager.bmi)) {
                        Text("Body Mass Index (BMI)")
                    }
                }

                Section(header: Text("Sleep")) {
                    NavigationLink(destination: MetricGraphView(title: "Sleep", samples: healthManager.sleep)) {
                        Text("Sleep Temperature")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Correlate")
        }
    }
}
