//
//  CorrelationView.swift
//  Correlate
//
//  Created by Blake Rayvid on 4/12/25.

extension Double {
    func normalized(in array: [Double]) -> Double {
        guard let min = array.min(), let max = array.max(), max != min else { return 0.5 }
        return (self - min) / (max - min)
    }
}

import SwiftUI
import HealthKit

extension Array where Element == Double {
    var average: Double {
        isEmpty ? 0 : reduce(0, +) / Double(count)
    }
}

func truncate(_ date: Date, to granularity: Calendar.Component) -> Date {
    Calendar.current.dateInterval(of: granularity, for: date)?.start ?? date
}

struct CorrelationView: View {
    @EnvironmentObject var healthManager: HealthManager

    @State private var metric1: String = "Steps"
    @State private var metric2: String = "Body Mass"
    @State private var correlationResult: Double? = nil
    @State private var currentPoints: [(Double, Double)] = []

    let metricOptions: [String] = [
        "Steps", "Active Energy","Dietary Energy", "Protein", "Fat", "Carbohydrates",
        "Heart Rate", "HRV", "Body Mass", "BMI", "Sleep"
    ]

    var body: some View {
        VStack {
            Text("Correlate Metrics")
                .font(.headline)
                .padding()

            Picker("Metric 1", selection: $metric1) {
                ForEach(metricOptions, id: \.self) { metric in
                    Text(metric).tag(metric)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()

            Picker("Metric 2", selection: $metric2) {
                ForEach(metricOptions, id: \.self) { metric in
                    Text(metric).tag(metric)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()

            Button("Compute Correlation") {
                computeCorrelation()
            }
            .padding()

            if let result = correlationResult {
                Text("Correlation Coefficient: \(String(format: "%.2f", result))")
                    .font(.title2)
                    .padding()

                VStack(alignment: .leading) {
    Text("\(metric1) vs \(metric2)")
        .font(.subheadline)
        .padding(.leading)
            GeometryReader { geo in
                let points = currentPoints
                ZStack(alignment: .topLeading) {
                    Color(.systemGray6)

                    ForEach(Array(points.enumerated()), id: \.0) { i, point in
                        let xNorm = point.0.normalized(in: points.map(\.0))
                        let yNorm = point.1.normalized(in: points.map(\.1))
                        let x = geo.size.width * (0.1 + 0.8 * CGFloat(xNorm))
                        let y = geo.size.height * (0.9 - 0.8 * CGFloat(yNorm))
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)
                    }

                    VStack {
                        Text(String(format: "%.1f", points.map(\.1).max() ?? 0))
                        Spacer()
                        Text(String(format: "%.1f", points.map(\.1).min() ?? 0))
                            .offset(y: -15)
                    }
                    .font(.caption2)
                    .padding(.vertical, 4)

                    // Y-axis label (rotated, centered vertically)
                    Text("\(metric2) (\(unitLabel(for: metric2)))")
                        .font(.caption)
                        .rotationEffect(.degrees(-90))
                        .position(x: 10, y: geo.size.height / 2)


                    // X-axis label (centered at bottom)
                    Text(metric1)
                        .font(.caption)
                        .position(x: geo.size.width / 2, y: geo.size.height - 10)


                    HStack {
                        Text(String(format: "%.1f", points.map(\.0).min() ?? 0))
                        Spacer()
                        Text(String(format: "%.1f", points.map(\.0).max() ?? 0))
                    }
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.top, geo.size.height - 16)
                }
            }
            .frame(height: 200)

}
            }

            Spacer()
        }
        .padding()
    }

    func computeCorrelation() {
        let data1 = samples(for: metric1)
        let data2 = samples(for: metric2)

        guard let s1 = data1, let s2 = data2, !s1.isEmpty, !s2.isEmpty else {
            correlationResult = nil
            return
        }

        let grouped1 = Dictionary(grouping: s1) { truncate($0.startDate, to: .day) }
        let grouped2 = Dictionary(grouping: s2) { truncate($0.startDate, to: .day) }

        let commonDates = Set(grouped1.keys).intersection(grouped2.keys)

        let pairedValues: [(Double, Double)] = commonDates.compactMap { date in
            guard let group1 = grouped1[date], let group2 = grouped2[date] else { return nil }
            let val1 = group1.map { $0.quantity.doubleValue(for: unit(for: metric1)) }.average
            let val2 = group2.map { $0.quantity.doubleValue(for: unit(for: metric2)) }.average
            return (val1, val2)
        }

        let x = pairedValues.map(\.0)
        let y = pairedValues.map(\.1)

        guard x.count > 1 else {
            correlationResult = nil
            return
        }

        correlationResult = pearsonCorrelation(x: x, y: y)
        currentPoints = pairedValues
    }


    func correlationPoints() -> [(Double, Double)] {
        let data1 = samples(for: metric1)
        let data2 = samples(for: metric2)

        guard let s1 = data1, let s2 = data2, !s1.isEmpty, !s2.isEmpty else {
            return []
        }

        let grouped1 = Dictionary(grouping: s1) { Calendar.current.startOfDay(for: $0.startDate) }
        let grouped2 = Dictionary(grouping: s2) { Calendar.current.startOfDay(for: $0.startDate) }
        let commonDates = Set(grouped1.keys).intersection(grouped2.keys)

        let paired: [(Double, Double)] = commonDates.compactMap { date in
            guard let g1 = grouped1[date], let g2 = grouped2[date] else { return nil }
            let v1 = g1.map { $0.quantity.doubleValue(for: unit(for: metric1)) }.average
            let v2 = g2.map { $0.quantity.doubleValue(for: unit(for: metric2)) }.average
            return (v1, v2) as (Double, Double)?
        }

        return paired
    }

    func samples(for metric: String) -> [HKQuantitySample]? {
        switch metric {
        case "Steps": return healthManager.steps
        case "Active Energy": return healthManager.activeEnergy
        case "Dietary Energy": return healthManager.dietaryEnergy
        case "Protein": return healthManager.protein
        case "Fat": return healthManager.fat
        case "Carbohydrates": return healthManager.carbohydrates
        case "Heart Rate": return healthManager.heartRate
        case "HRV": return healthManager.hrv
        case "Body Mass": return healthManager.bodyMass
        case "BMI": return healthManager.bmi
        case "Sleep": return healthManager.sleep
        default: return nil
        }
    }

    func unit(for metric: String) -> HKUnit {
        switch metric.lowercased() {
        case "active energy": return .kilocalorie()
        case "dietary energy": return .kilocalorie()
        case "protein", "fat", "carbohydrates": return .gram()
        case "heart rate": return HKUnit(from: "count/min")
        case "hrv": return HKUnit.secondUnit(with: .milli)
        case "body mass": return .gramUnit(with: .kilo)
        case "bmi": return HKUnit.count()
        case "sleep": return .hour()
        case "steps": return .count()
        default: return .count()
        }
    }

    func pearsonCorrelation(x: [Double], y: [Double]) -> Double {
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)

        let numerator = (n * sumXY) - (sumX * sumY)
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        return denominator == 0 ? 0 : numerator / denominator
    }
    
    func unitLabel(for metric: String) -> String {
        switch metric.lowercased() {
        case "active energy": return "kcal"
        case "dietary energy": return "kcal"
        case "protein", "fat", "carbohydrates": return "g"
        case "heart rate": return "bpm"
        case "hrv": return "ms"
        case "body mass": return "kg"
        case "bmi": return "" // unitless
        case "sleep": return "hrs"
        case "steps": return "count"
        default: return ""
        }
    }

}







