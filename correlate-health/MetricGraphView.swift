//
//  MetricGraphView.swift
//  Correlate
//
//  Created by Blake Rayvid on 4/12/25.
import SwiftUI
import HealthKit

struct MetricGraphView: View {
    var title: String
    var samples: [HKQuantitySample]

    @EnvironmentObject var healthManager: HealthManager
    @State private var selectedGranularity: Calendar.Component = .day
    @State private var visibleIndices: Set<Int> = []
    @State private var dynamicMaxValue: Double = 1
    @State private var dynamicMinValue: Double = 0

    private var barWidth: CGFloat {
        switch selectedGranularity {
        case .weekOfYear: return 8
        case .month: return 12
        case .year: return 16
        default: return 4
        }
    }

    private let spacing: CGFloat = 0.5

    var isLineChart: Bool {
        let lower = title.lowercased()
        return lower.contains("heart rate") || lower.contains("hrv") || lower.contains("body mass") || lower.contains("bmi")
    }

    var body: some View {
        VStack {
            Text("\(title) Trend")
                .font(.headline)

            Picker("View By", selection: $selectedGranularity) {
                Text("Daily").tag(Calendar.Component.day)
                Text("Weekly").tag(Calendar.Component.weekOfYear)
                Text("Monthly").tag(Calendar.Component.month)
                Text("Yearly").tag(Calendar.Component.year)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            let averagedData = healthManager.average(samples: samples, by: selectedGranularity, using: unit(for: title))

            GeometryReader { geometry in
                let availableHeight = geometry.size.height * 0.6
                let maxValue = max(dynamicMaxValue, 1)
                let minValue = isLineChart ? dynamicMinValue : 0
                let barHeightMultiplier = availableHeight / max(maxValue - minValue, 1)
                let contentWidth = CGFloat(averagedData.count) * (barWidth + spacing)
                let fullWidth = max(contentWidth + geometry.size.width * 0.4, geometry.size.width)

                VStack {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal) {
                            ZStack(alignment: .bottomLeading) {
                                if isLineChart {
                                    Path { path in
                                        for (i, dataPoint) in averagedData.enumerated() {
                                            let x = CGFloat(i) * (barWidth + spacing) + geometry.size.width * 0.2
                                            let adjustedValue = dataPoint.value - minValue
                                            let y = availableHeight - CGFloat(adjustedValue) * barHeightMultiplier
                                            if i == 0 {
                                                path.move(to: CGPoint(x: x, y: y))
                                            } else {
                                                path.addLine(to: CGPoint(x: x, y: y))
                                            }
                                        }
                                    }
                                    .stroke(Color.red, lineWidth: 2)
                                    .frame(width: fullWidth, height: availableHeight + 20)
                                }

                                HStack(alignment: .bottom, spacing: spacing) {
                                    ForEach(Array(averagedData.enumerated()), id: \.offset) { index, dataPoint in
                                        VStack(spacing: 0) {
                                            if !isLineChart {
                                                Rectangle()
                                                    .frame(width: barWidth, height: CGFloat(dataPoint.value - minValue) * barHeightMultiplier)
                                                    .foregroundColor(.blue)
                                            }
                                            if index % labelInterval(for: selectedGranularity) == 0 {
                                                Text(formattedDate(dataPoint.date, component: selectedGranularity))
                                                    .font(.system(size: 7))
                                                    .rotationEffect(.degrees(-45))
                                                    .frame(width: 28)
                                            } else {
                                                Text("")
                                                    .frame(width: 0, height: 0)
                                            }
                                        }
                                        .background(GeometryReader { barGeo in
                                            Color.clear.preference(key: VisibleBarPreferenceKey.self, value: [VisibleBar(index: index, minX: barGeo.frame(in: .named("scroll")).minX, maxX: barGeo.frame(in: .named("scroll")).maxX)])
                                        })
                                        .id(index)
                                    }
                                }
                                .padding(.leading, geometry.size.width * 0.2)
                                .padding(.trailing, geometry.size.width * 0.2)
                            }
                            .frame(width: fullWidth, height: availableHeight + 20)
                            .coordinateSpace(name: "scroll")
                            .onPreferenceChange(VisibleBarPreferenceKey.self) { values in
                                let visible = values.filter { $0.minX >= 0 && $0.maxX <= geometry.size.width }
                                let newVisibleIndices = Set(visible.map { $0.index })
                                if newVisibleIndices != visibleIndices {
                                    visibleIndices = newVisibleIndices

                                    let visibleData = averagedData.enumerated().filter { visibleIndices.contains($0.offset) }.map { $0.element }
                                    dynamicMaxValue = visibleData.map { $0.value }.max() ?? 1
                                    dynamicMinValue = isLineChart ? (visibleData.map { $0.value }.min() ?? 0) : 0
                                }
                            }
                            .task {
                                if let last = averagedData.indices.last {
                                    try? await Task.sleep(nanoseconds: 200_000_000)
                                    withAnimation {
                                        proxy.scrollTo(last, anchor: .center)
                                    }
                                }
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(.vertical)
    }

    private func labelInterval(for component: Calendar.Component) -> Int {
        switch component {
        case .day: return 7
        case .weekOfYear: return 4
        case .month: return 2
        case .year: return 1
        default: return 5
        }
    }

    private func formattedDate(_ date: Date, component: Calendar.Component) -> String {
        let formatter = DateFormatter()
        switch component {
        case .day:
            formatter.dateFormat = "MM/dd"
        case .weekOfYear:
            formatter.dateFormat = "'Wk' w"
        case .month:
            formatter.dateFormat = "MMM yy"
        case .year:
            formatter.dateFormat = "yyyy"
        default:
            formatter.dateFormat = "MM/dd"
        }
        return formatter.string(from: date)
    }

    private func unit(for title: String) -> HKUnit {
        switch title.lowercased() {
        case "active energy": return .kilocalorie()
        case "dietary energy": return .kilocalorie()
        case "protein", "dietary protein":
            return .gram()
        case "fat", "dietary fat":
            return .gram()
        case "carbohydrates", "carbs":
            return .gram()
        case "heart rate":
            return HKUnit(from: "count/min")
        case "hrv":
            return HKUnit.secondUnit(with: .milli)
        case "weight", "body mass":
            return .gramUnit(with: .kilo)
        case "bmi":
            return HKUnit.count()
        case "sleep", "temperature":
            return .degreeCelsius()
        case "step count", "steps":
            return .count()
        default:
            return .count()
        }
    }
}

struct VisibleBar: Equatable {
    let index: Int
    let minX: CGFloat
    let maxX: CGFloat
}

struct VisibleBarPreferenceKey: PreferenceKey {
    static var defaultValue: [VisibleBar] = []

    static func reduce(value: inout [VisibleBar], nextValue: () -> [VisibleBar]) {
        value.append(contentsOf: nextValue())
    }
}
