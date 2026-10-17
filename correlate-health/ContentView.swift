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
                if healthManager.isLoading {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("Reading Apple Health metrics...")
                            .foregroundColor(.secondary)
                    }
                }

                ForEach(MetricCategory.allCases) { category in
                    let metrics = HealthCatalog.allMetrics.filter { $0.category == category }
                    Section(header: Label(category.rawValue, systemImage: category.icon)) {
                        ForEach(metrics) { metric in
                            NavigationLink(destination: MetricGraphView(metric: metric)) {
                                MetricRowView(
                                    metric: metric,
                                    latestValueText: latestValue(for: metric)
                                )
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Health Dashboard")
            .refreshable {
                healthManager.fetchAllData()
            }
        }
    }

    private func latestValue(for metric: HealthMetricType) -> String? {
        guard let dayData = healthManager.dailySeries[metric.id], !dayData.isEmpty else {
            return nil
        }
        let sortedDates = dayData.keys.sorted(by: >)
        guard let latestDate = sortedDates.first, let value = dayData[latestDate] else { return nil }
        return String(format: "%.1f", value)
    }
}

// Extracted subview to keep type-checking complexity low and instantaneous
struct MetricRowView: View {
    let metric: HealthMetricType
    let latestValueText: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: metric.icon)
                .foregroundColor(metric.color)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(metric.displayName)
                    .font(.body)

                if let latestVal = latestValueText {
                    Text("Latest: \(latestVal) \(metric.unitLabel)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("No recent entries")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }
}
