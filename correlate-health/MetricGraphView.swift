//
//  MetricGraphView.swift
//  Correlate
//
//  Created by Blake Rayvid on 4/12/25.
//

import SwiftUI
import Charts
import HealthKit

struct MetricGraphView: View {
    let metric: HealthMetricType
    @EnvironmentObject var healthManager: HealthManager

    @State private var selectedGranularity: Calendar.Component = .day
    @State private var selectedChartStyle: ChartStyle = .standard
    @State private var selectedTransform: TransformType = .raw

    enum ChartStyle: String, CaseIterable, Identifiable {
        case standard = "Auto"
        case line = "Line"
        case bar = "Bar"
        case area = "Area"
        var id: String { rawValue }
    }

    struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    var chartData: [ChartPoint] {
        guard let baseDaily = healthManager.dailySeries[metric.id] else { return [] }
        let transformedDaily = TimeSeriesTransforms.transform(dailySeries: baseDaily, type: selectedTransform)
        
        if selectedGranularity == .day {
            return transformedDaily.map { ChartPoint(date: $0.key, value: $0.value) }
                .sorted { $0.date < $1.date }
        }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transformedDaily.keys) { date -> Date in
            calendar.dateInterval(of: selectedGranularity, for: date)?.start ?? date
        }

        var aggregated: [ChartPoint] = []
        for (bucketDate, dates) in grouped {
            let values = dates.compactMap { transformedDaily[$0] }
            guard !values.isEmpty else { continue }
            let val = (metric.aggregation == .cumulativeSum && selectedTransform == .raw)
                ? values.reduce(0, +)
                : (values.reduce(0, +) / Double(values.count))
            aggregated.append(ChartPoint(date: bucketDate, value: val))
        }

        return aggregated.sorted { $0.date < $1.date }
    }

    var stats: (avg: Double, min: Double, max: Double, total: Double, latest: Double)? {
        let vals = chartData.map(\.value)
        guard !vals.isEmpty else { return nil }
        let total = vals.reduce(0, +)
        let avg = total / Double(vals.count)
        return (
            avg: avg,
            min: vals.min() ?? 0,
            max: vals.max() ?? 0,
            total: total,
            latest: vals.last ?? 0
        )
    }

    var effectiveIsLine: Bool {
        switch selectedChartStyle {
        case .line: return true
        case .bar: return false
        case .area: return true
        case .standard: return metric.defaultLineChart || selectedTransform.isDerivative
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header & Controls
                VStack(spacing: 12) {
                    Picker("Granularity", selection: $selectedGranularity) {
                        Text("Daily").tag(Calendar.Component.day)
                        Text("Weekly").tag(Calendar.Component.weekOfYear)
                        Text("Monthly").tag(Calendar.Component.month)
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    HStack {
                        Menu {
                            Picker("Series Transform", selection: $selectedTransform) {
                                ForEach(TransformType.allCases) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "function")
                                Text(selectedTransform.rawValue)
                                Image(systemName: "chevron.down")
                            }
                            .font(.subheadline.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }

                        Spacer()

                        Picker("Chart Style", selection: $selectedChartStyle) {
                            ForEach(ChartStyle.allCases) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(maxWidth: 200)
                    }
                }
                .padding(.horizontal)

                // Stats Dashboard Bar
                if let s = stats {
                    HStack(spacing: 12) {
                        StatCard(title: "Latest", value: String(format: "%.1f", s.latest), unit: metric.unitLabel)
                        StatCard(title: "Average", value: String(format: "%.1f", s.avg), unit: metric.unitLabel)
                        StatCard(title: "Min", value: String(format: "%.1f", s.min), unit: metric.unitLabel)
                        StatCard(title: "Max", value: String(format: "%.1f", s.max), unit: metric.unitLabel)
                    }
                    .padding(.horizontal)
                }

                // Main Uniform Chart View
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: metric.icon)
                            .foregroundColor(metric.color)
                        Text("\(metric.displayName)\(selectedTransform.shortSuffix)")
                            .font(.headline)
                        Spacer()
                        Text("Units: \(metric.unitLabel)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    if chartData.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No recorded data for \(metric.displayName)")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, minHeight: 280)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        Chart(chartData) { point in
                            if selectedChartStyle == .area {
                                AreaMark(
                                    x: .value("Date", point.date),
                                    y: .value(metric.unitLabel, point.value)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [metric.color.opacity(0.4), metric.color.opacity(0.05)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)

                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value(metric.unitLabel, point.value)
                                )
                                .foregroundStyle(metric.color)
                                .lineStyle(StrokeStyle(lineWidth: 2))
                                .interpolationMethod(.catmullRom)
                            } else if effectiveIsLine {
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value(metric.unitLabel, point.value)
                                )
                                .foregroundStyle(metric.color)
                                .lineStyle(StrokeStyle(lineWidth: 2.2))
                                .interpolationMethod(.catmullRom)

                                PointMark(
                                    x: .value("Date", point.date),
                                    y: .value(metric.unitLabel, point.value)
                                )
                                .foregroundStyle(metric.color)
                                .symbolSize(chartData.count > 60 ? 0 : 18)
                            } else {
                                BarMark(
                                    x: .value("Date", point.date, unit: calendarUnit(selectedGranularity)),
                                    y: .value(metric.unitLabel, point.value)
                                )
                                .foregroundStyle(metric.color.gradient)
                                .cornerRadius(3)
                            }

                            if let s = stats {
                                RuleMark(y: .value("Average", s.avg))
                                    .foregroundStyle(Color.secondary.opacity(0.7))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                    .annotation(position: .top, alignment: .trailing) {
                                        Text("Avg: \(String(format: "%.1f", s.avg)) \(metric.unitLabel)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .padding(2)
                                    }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                                    .foregroundStyle(Color.gray.opacity(0.3))
                                AxisTick()
                                AxisValueLabel {
                                    if let d = value.as(Double.self) {
                                        Text(String(format: "%.0f", d))
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                                    .foregroundStyle(Color.gray.opacity(0.2))
                                AxisTick()
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        Text(date, format: dateChartFormat(for: selectedGranularity))
                                    }
                                }
                            }
                        }
                        .chartYScale(domain: yDomain)
                        .frame(height: 320)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                        .padding(.horizontal)
                    }
                }

                // Insights & Context Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("About \(metric.displayName)")
                        .font(.headline)
                    Text("Category: \(metric.category.rawValue) • Aggregated by \(metric.aggregation == .cumulativeSum ? "Daily Total" : "Daily Average"). Derivatives (Δ) show day-over-day changes to detect trends.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(metric.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var yDomain: ClosedRange<Double> {
        let values = chartData.map(\.value)
        guard let minVal = values.min(), let maxVal = values.max() else { return 0...100 }
        if selectedTransform.isDerivative {
            let bound = max(abs(minVal), abs(maxVal)) * 1.15
            return (-bound)...(bound == 0 ? 1 : bound)
        }
        if effectiveIsLine {
            let padding = max((maxVal - minVal) * 0.15, 1.0)
            return max(0, minVal - padding)...(maxVal + padding)
        } else {
            return 0...(maxVal * 1.15)
        }
    }

    private func calendarUnit(_ component: Calendar.Component) -> Calendar.Component {
        switch component {
        case .weekOfYear: return .weekOfYear
        case .month: return .month
        default: return .day
        }
    }

    private func dateChartFormat(for component: Calendar.Component) -> Date.FormatStyle {
            switch component {
            case .day:
                return .dateTime.month(.defaultDigits).day(.defaultDigits)
            case .weekOfYear:
                return .dateTime.month(.abbreviated).day(.defaultDigits)
            case .month:
                return .dateTime.month(.abbreviated)
            default:
                return .dateTime.month(.defaultDigits).day(.defaultDigits)
            }
        }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline.bold())
                Text(unit)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }
}
