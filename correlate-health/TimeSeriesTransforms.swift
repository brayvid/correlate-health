//
//  TimeSeriesTransforms.swift
//  Correlate
//
//  Created by Blake Rayvid on 4/12/25.
//

import Foundation

// MARK: - Synthetic Feature Transformation Mode
enum TransformType: String, CaseIterable, Identifiable, Codable {
    case raw = "Raw Series"
    case delta1Day = "1-Day Δ (Rate of Change)"
    case delta7Day = "7-Day Δ (Rate of Change)"
    case lag1Day = "Lag: 1 Day Ago (t-1)"
    case lag2Day = "Lag: 2 Days Ago (t-2)"
    case lag3Day = "Lag: 3 Days Ago (t-3)"
    case lag7Day = "Lag: 7 Days Ago (t-7)"
    
    var id: String { rawValue }
    
    var shortSuffix: String {
        switch self {
        case .raw: return ""
        case .delta1Day: return " [Δ1d]"
        case .delta7Day: return " [Δ7d]"
        case .lag1Day: return " [t-1d]"
        case .lag2Day: return " [t-2d]"
        case .lag3Day: return " [t-3d]"
        case .lag7Day: return " [t-7d]"
        }
    }
    
    var isLag: Bool {
        return self == .lag1Day || self == .lag2Day || self == .lag3Day || self == .lag7Day
    }
    
    var isDerivative: Bool {
        return self == .delta1Day || self == .delta7Day
    }
}

// MARK: - Feature Identifier for Correlation Matrix
struct FeatureIdentifier: Hashable, Identifiable, Codable {
    let metricId: String
    let transform: TransformType
    
    var id: String {
        "\(metricId)_\(transform.rawValue)"
    }
    
    func name(with catalogMetric: HealthMetricType?) -> String {
        let base = catalogMetric?.displayName ?? metricId
        return "\(base)\(transform.shortSuffix)"
    }
}

// MARK: - Mathematical Transformations & Linear Interpolation
struct TimeSeriesTransforms {
    
    /// Linearly interpolates missing days between discrete measurements.
    static func linearlyInterpolated(dailySeries: [Date: Double], maxGapDays: Int = 21) -> [Date: Double] {
        guard dailySeries.count >= 2 else { return dailySeries }
        let calendar = Calendar.current

        var normalized: [Date: Double] = [:]
        for (date, val) in dailySeries {
            let start = calendar.startOfDay(for: date)
            normalized[start] = val
        }

        let sortedDates = normalized.keys.sorted()
        var interpolated = normalized

        for i in 0..<(sortedDates.count - 1) {
            let d0 = sortedDates[i]
            let d1 = sortedDates[i + 1]
            guard let v0 = normalized[d0], let v1 = normalized[d1] else { continue }

            let gap = calendar.dateComponents([.day], from: d0, to: d1).day ?? 0
            if gap > 1 && gap <= maxGapDays {
                for step in 1..<gap {
                    if let interpolatedDate = calendar.date(byAdding: .day, value: step, to: d0) {
                        let fraction = Double(step) / Double(gap)
                        let interpolatedVal = v0 + fraction * (v1 - v0)
                        interpolated[interpolatedDate] = interpolatedVal
                    }
                }
            }
        }

        return interpolated
    }
    
    /// Applies numerical derivative or time-lag transformations to a daily series
    static func transform(dailySeries: [Date: Double], type: TransformType, interpolateGaps: Bool = true) -> [Date: Double] {
        guard !dailySeries.isEmpty else { return [:] }
        let calendar = Calendar.current
        
        let workingSeries: [Date: Double]
        if interpolateGaps && (type.isDerivative || dailySeries.count < 45) {
            workingSeries = linearlyInterpolated(dailySeries: dailySeries, maxGapDays: 21)
        } else {
            var norm: [Date: Double] = [:]
            for (date, val) in dailySeries {
                norm[calendar.startOfDay(for: date)] = val
            }
            workingSeries = norm
        }

        let sortedDates = workingSeries.keys.sorted()
        var transformed: [Date: Double] = [:]

        switch type {
        case .raw:
            return workingSeries

        case .delta1Day:
            for i in 1..<sortedDates.count {
                let currentDate = sortedDates[i]
                let prevDate = sortedDates[i - 1]
                let dayDiff = calendar.dateComponents([.day], from: prevDate, to: currentDate).day ?? 0
                if dayDiff == 1 {
                    let vCurrent = workingSeries[currentDate]!
                    let vPrev = workingSeries[prevDate]!
                    transformed[currentDate] = vCurrent - vPrev
                }
            }

        case .delta7Day:
            for i in 0..<sortedDates.count {
                let currentDate = sortedDates[i]
                if let date7dAgo = calendar.date(byAdding: .day, value: -7, to: currentDate),
                   let v7dAgo = workingSeries[date7dAgo],
                   let vCurrent = workingSeries[currentDate] {
                    transformed[currentDate] = vCurrent - v7dAgo
                }
            }

        case .lag1Day:
            for (date, val) in workingSeries {
                if let shifted = calendar.date(byAdding: .day, value: 1, to: date) {
                    transformed[shifted] = val
                }
            }

        case .lag2Day:
            for (date, val) in workingSeries {
                if let shifted = calendar.date(byAdding: .day, value: 2, to: date) {
                    transformed[shifted] = val
                }
            }

        case .lag3Day:
            for (date, val) in workingSeries {
                if let shifted = calendar.date(byAdding: .day, value: 3, to: date) {
                    transformed[shifted] = val
                }
            }

        case .lag7Day:
            for (date, val) in workingSeries {
                if let shifted = calendar.date(byAdding: .day, value: 7, to: date) {
                    transformed[shifted] = val
                }
            }
        }

        return transformed
    }

    /// Pearson correlation coefficient r between two series paired on common dates
    static func pearsonCorrelation(seriesA: [Date: Double], seriesB: [Date: Double]) -> (r: Double, points: [(date: Date, x: Double, y: Double)], n: Int)? {
        let calendar = Calendar.current
        
        let cleanA = Dictionary(uniqueKeysWithValues: seriesA.map { (calendar.startOfDay(for: $0.key), $0.value) })
        let cleanB = Dictionary(uniqueKeysWithValues: seriesB.map { (calendar.startOfDay(for: $0.key), $0.value) })
        
        let commonDates = Set(cleanA.keys).intersection(cleanB.keys)
        guard commonDates.count >= 4 else { return nil }
        
        let pairs: [(date: Date, x: Double, y: Double)] = commonDates.compactMap { d in
            guard let valA = cleanA[d], let valB = cleanB[d],
                  valA.isFinite, valB.isFinite else { return nil }
            return (date: d, x: valA, y: valB)
        }.sorted { $0.date < $1.date }
        
        let n = Double(pairs.count)
        guard n >= 4 else { return nil }
        
        let x = pairs.map(\.x)
        let y = pairs.map(\.y)
        
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let num = (n * sumXY) - (sumX * sumY)
        let varX = (n * sumX2) - (sumX * sumX)
        let varY = (n * sumY2) - (sumY * sumY)
        
        // Realistic numerical variance guard (avoid dividing by zero, but do not drop gradual linear changes)
        guard varX > 1e-12, varY > 1e-12 else { return nil }
        
        let den = sqrt(varX * varY)
        guard den > 0 else { return nil }
        
        let r = num / den
        guard r.isFinite else { return nil }
        
        return (r: max(-1.0, min(1.0, r)), points: pairs, n: pairs.count)
    }
}
