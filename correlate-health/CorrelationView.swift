//
//  CorrelationView.swift
//  Correlate
//
//  Created by Blake Rayvid on 4/12/25.
//

import SwiftUI
import Charts
import HealthKit

struct CorrelationView: View {
    @EnvironmentObject var healthManager: HealthManager

    @State private var metricId1: String = "steps"
    @State private var transform1: TransformType = .raw

    @State private var metricId2: String = "restingHeartRate"
    @State private var transform2: TransformType = .raw

    @State private var correlationResult: Double? = nil
    @State private var pairedPoints: [(date: Date, x: Double, y: Double)] = []

    var metric1: HealthMetricType {
        HealthCatalog.allMetrics.first { $0.id == metricId1 } ?? HealthCatalog.allMetrics[0]
    }

    var metric2: HealthMetricType {
        HealthCatalog.allMetrics.first { $0.id == metricId2 } ?? HealthCatalog.allMetrics[1]
    }

    // Dynamic X scale tightly fit to data points (does not force 0)
    var xDomain: ClosedRange<Double> {
        let xs = pairedPoints.map(\.x)
        guard let minVal = xs.min(), let maxVal = xs.max(), minVal != maxVal else {
            let single = xs.first ?? 0
            return (single - 1)...(single + 1)
        }
        let padding = (maxVal - minVal) * 0.06
        return (minVal - padding)...(maxVal + padding)
    }

    // Dynamic Y scale tightly fit to data points (does not force 0)
    var yDomain: ClosedRange<Double> {
        let ys = pairedPoints.map(\.y)
        guard let minVal = ys.min(), let maxVal = ys.max(), minVal != maxVal else {
            let single = ys.first ?? 0
            return (single - 1)...(single + 1)
        }
        let padding = (maxVal - minVal) * 0.06
        return (minVal - padding)...(maxVal + padding)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Selector Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Select Variables to Correlate")
                            .font(.headline)

                        // Metric 1 (X Axis)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("X-AXIS (INDEPENDENT)")
                                .font(.caption2.bold())
                                .foregroundColor(.secondary)

                            HStack {
                                Picker("Metric 1", selection: $metricId1) {
                                    ForEach(HealthCatalog.allMetrics) { m in
                                        Text(m.displayName).tag(m.id)
                                    }
                                }
                                .pickerStyle(.menu)

                                Spacer()

                                Picker("Transform", selection: $transform1) {
                                    ForEach(TransformType.allCases) { t in
                                        Text(t.rawValue).tag(t)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .padding(8)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(8)
                        }

                        // Metric 2 (Y Axis)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Y-AXIS (DEPENDENT)")
                                .font(.caption2.bold())
                                .foregroundColor(.secondary)

                            HStack {
                                Picker("Metric 2", selection: $metricId2) {
                                    ForEach(HealthCatalog.allMetrics) { m in
                                        Text(m.displayName).tag(m.id)
                                    }
                                }
                                .pickerStyle(.menu)

                                Spacer()

                                Picker("Transform", selection: $transform2) {
                                    ForEach(TransformType.allCases) { t in
                                        Text(t.rawValue).tag(t)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .padding(8)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(8)
                        }

                        Button(action: computeCorrelation) {
                            HStack {
                                Image(systemName: "chart.xyaxis.line")
                                Text("Compute Correlation")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    .padding(.horizontal)

                    // Results Presentation
                    if let r = correlationResult, !pairedPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            // Score Card
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Pearson Correlation (r)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%+.3f", r))
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .foregroundColor(rColor(r))
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(strengthDescription(r))
                                        .font(.subheadline.bold())
                                        .foregroundColor(rColor(r))
                                    Text("\(pairedPoints.count) matching days")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.bottom, 4)

                            // Scatter Plot fitted to data
                            let xTitle = "\(metric1.displayName)\(transform1.shortSuffix) (\(metric1.unitLabel))"
                            let yTitle = "\(metric2.displayName)\(transform2.shortSuffix) (\(metric2.unitLabel))"

                            Chart {
                                ForEach(Array(pairedPoints.enumerated()), id: \.offset) { _, pt in
                                    PointMark(
                                        x: .value(xTitle, pt.x),
                                        y: .value(yTitle, pt.y)
                                    )
                                    .foregroundStyle(Color.blue.opacity(0.65))
                                    .symbolSize(30)
                                }

                                // Linear Regression Trendline fit across actual observed xMin...xMax
                                if let reg = linearRegression(points: pairedPoints) {
                                    LineMark(
                                        x: .value("X", reg.xMin),
                                        y: .value("Y", reg.slope * reg.xMin + reg.intercept)
                                    )
                                    .foregroundStyle(Color.red)
                                    .lineStyle(StrokeStyle(lineWidth: 2.2))

                                    LineMark(
                                        x: .value("X", reg.xMax),
                                        y: .value("Y", reg.slope * reg.xMax + reg.intercept)
                                    )
                                    .foregroundStyle(Color.red)
                                    .lineStyle(StrokeStyle(lineWidth: 2.2))
                                }
                            }
                            .chartXScale(domain: xDomain)
                            .chartYScale(domain: yDomain)
                            .chartXAxis {
                                AxisMarks(values: .automatic) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                                        .foregroundStyle(Color.gray.opacity(0.2))
                                    AxisTick()
                                    AxisValueLabel {
                                        if let v = value.as(Double.self) {
                                            Text(String(format: "%.1f", v))
                                                .font(.caption2)
                                        }
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading, values: .automatic) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                                        .foregroundStyle(Color.gray.opacity(0.2))
                                    AxisTick()
                                    AxisValueLabel {
                                        if let v = value.as(Double.self) {
                                            Text(String(format: "%.1f", v))
                                                .font(.caption2)
                                        }
                                    }
                                }
                            }
                            .chartXAxisLabel(xTitle, alignment: .center)
                            .chartYAxisLabel(yTitle, position: .leading)
                            .frame(height: 320)
                            .padding(.vertical, 8)

                            // Summary Interpretation
                            Text(explanationText(r: r, m1: metric1.displayName + transform1.shortSuffix, m2: metric2.displayName + transform2.shortSuffix))
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.tertiarySystemGroupedBackground))
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        .padding(.horizontal)
                    } else if correlationResult != nil {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundColor(.orange)
                            Text("Insufficient Overlapping Data")
                                .font(.headline)
                            Text("Both metrics require at least 5 shared calendar days of records.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Correlation Tool")
            .onAppear {
                if correlationResult == nil {
                    computeCorrelation()
                }
            }
        }
    }

    func computeCorrelation() {
        guard let raw1 = healthManager.dailySeries[metric1.id],
              let raw2 = healthManager.dailySeries[metric2.id] else {
            correlationResult = nil
            pairedPoints = []
            return
        }

        let s1 = TimeSeriesTransforms.transform(dailySeries: raw1, type: transform1)
        let s2 = TimeSeriesTransforms.transform(dailySeries: raw2, type: transform2)

        if let result = TimeSeriesTransforms.pearsonCorrelation(seriesA: s1, seriesB: s2) {
            correlationResult = result.r
            pairedPoints = result.points
        } else {
            correlationResult = 0
            pairedPoints = []
        }
    }

    private func linearRegression(points: [(date: Date, x: Double, y: Double)]) -> (slope: Double, intercept: Double, xMin: Double, xMax: Double)? {
        guard points.count >= 2 else { return nil }
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        guard let xMin = xs.min(), let xMax = xs.max(), xMin != xMax else { return nil }
        let n = Double(points.count)
        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).map(*).reduce(0, +)
        let sumX2 = xs.map { $0 * $0 }.reduce(0, +)
        let denom = (n * sumX2 - sumX * sumX)
        guard denom != 0 else { return nil }
        let slope = (n * sumXY - sumX * sumY) / denom
        let intercept = (sumY - slope * sumX) / n
        return (slope, intercept, xMin, xMax)
    }

    private func rColor(_ r: Double) -> Color {
        if abs(r) >= 0.6 { return r > 0 ? .green : .red }
        if abs(r) >= 0.3 { return .blue }
        return .secondary
    }

    private func strengthDescription(_ r: Double) -> String {
        let absR = abs(r)
        let dir = r >= 0 ? "Positive" : "Inverse"
        if absR >= 0.7 { return "Strong \(dir)" }
        if absR >= 0.4 { return "Moderate \(dir)" }
        if absR >= 0.2 { return "Weak \(dir)" }
        return "No Correlation"
    }

    private func explanationText(r: Double, m1: String, m2: String) -> String {
        let absR = abs(r)
        if absR < 0.2 {
            return "No meaningful statistical link observed between \(m1) and \(m2) in your data."
        }
        let dirWord = r > 0 ? "increases" : "decreases"
        return "When \(m1) increases, \(m2) tendentially \(dirWord) (r = \(String(format: "%.2f", r))). This represents a \(strengthDescription(r).lowercased()) relationship."
    }
}
