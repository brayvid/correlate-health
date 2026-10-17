//
//  HealthManager.swift
//  Correlate
//
//  Created by Blake Rayvid on 4/12/25.
//

import Foundation
import HealthKit
import SwiftUI

// MARK: - Metric Category Definition
enum MetricCategory: String, CaseIterable, Identifiable {
    case activity = "Activity & Mobility"
    case vitals = "Vitals & Heart"
    case nutrition = "Nutrition"
    case body = "Body Measurements"
    case sleepMindfulness = "Sleep & Mindfulness"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .activity: return "figure.walk"
        case .vitals: return "heart.fill"
        case .nutrition: return "leaf.fill"
        case .body: return "scalemass.fill"
        case .sleepMindfulness: return "bed.double.fill"
        }
    }
}

// MARK: - Metric Aggregation Style
enum AggregationType {
    case cumulativeSum  // Steps, calories, distance, water
    case averageDiscrete // Heart rate, HRV, weight, temperature
}

// MARK: - Health Metric Specification
struct HealthMetricType: Identifiable, Hashable {
    let id: String
    let displayName: String
    let category: MetricCategory
    let quantityIdentifier: HKQuantityTypeIdentifier?
    let categoryIdentifier: HKCategoryTypeIdentifier?
    let defaultUnit: HKUnit
    let unitLabel: String
    let aggregation: AggregationType
    let icon: String
    let color: Color
    let defaultLineChart: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: HealthMetricType, rhs: HealthMetricType) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Predefined All Health Metrics Catalog
struct HealthCatalog {
    static let allMetrics: [HealthMetricType] = [
        // Activity & Mobility
        HealthMetricType(
            id: "steps",
            displayName: "Steps",
            category: .activity,
            quantityIdentifier: .stepCount,
            categoryIdentifier: nil,
            defaultUnit: .count(),
            unitLabel: "steps",
            aggregation: .cumulativeSum,
            icon: "figure.walk",
            color: .blue,
            defaultLineChart: false
        ),
        HealthMetricType(
            id: "activeEnergy",
            displayName: "Active Energy",
            category: .activity,
            quantityIdentifier: .activeEnergyBurned,
            categoryIdentifier: nil,
            defaultUnit: .kilocalorie(),
            unitLabel: "kcal",
            aggregation: .cumulativeSum,
            icon: "flame.fill",
            color: .orange,
            defaultLineChart: false
        ),
        HealthMetricType(
            id: "basalEnergy",
            displayName: "Resting Energy",
            category: .activity,
            quantityIdentifier: .basalEnergyBurned,
            categoryIdentifier: nil,
            defaultUnit: .kilocalorie(),
            unitLabel: "kcal",
            aggregation: .cumulativeSum,
            icon: "bolt.fill",
            color: .red,
            defaultLineChart: false
        ),
        HealthMetricType(
            id: "distanceWalkingRunning",
            displayName: "Walking & Running Distance",
            category: .activity,
            quantityIdentifier: .distanceWalkingRunning,
            categoryIdentifier: nil,
            defaultUnit: .mile(),
            unitLabel: "mi",
            aggregation: .cumulativeSum,
            icon: "figure.run",
            color: .green,
            defaultLineChart: false
        ),
        HealthMetricType(
            id: "flightsClimbed",
            displayName: "Flights Climbed",
            category: .activity,
            quantityIdentifier: .flightsClimbed,
            categoryIdentifier: nil,
            defaultUnit: .count(),
            unitLabel: "flights",
            aggregation: .cumulativeSum,
            icon: "stairs",
            color: .cyan,
            defaultLineChart: false
        ),
        HealthMetricType(
            id: "exerciseTime",
            displayName: "Exercise Time",
            category: .activity,
            quantityIdentifier: .appleExerciseTime,
            categoryIdentifier: nil,
            defaultUnit: .minute(),
            unitLabel: "min",
            aggregation: .cumulativeSum,
            icon: "timer",
            color: .green,
            defaultLineChart: false
        ),
        HealthMetricType(
            id: "standTime",
            displayName: "Stand Time",
            category: .activity,
            quantityIdentifier: .appleStandTime,
            categoryIdentifier: nil,
            defaultUnit: .minute(),
            unitLabel: "min",
            aggregation: .cumulativeSum,
            icon: "figure.stand",
            color: .indigo,
            defaultLineChart: false
        ),
        HealthMetricType(
            id: "walkingSpeed",
            displayName: "Walking Speed",
            category: .activity,
            quantityIdentifier: .walkingSpeed,
            categoryIdentifier: nil,
            defaultUnit: HKUnit(from: "mi/hr"),
            unitLabel: "mph",
            aggregation: .averageDiscrete,
            icon: "gauge.with.needle",
            color: .teal,
            defaultLineChart: true
        ),
        HealthMetricType(
            id: "walkingStepLength",
            displayName: "Walking Step Length",
            category: .activity,
            quantityIdentifier: .walkingStepLength,
            categoryIdentifier: nil,
            defaultUnit: .inch(),
            unitLabel: "in",
            aggregation: .averageDiscrete,
            icon: "ruler.fill",
            color: .mint,
            defaultLineChart: true
        ),
        HealthMetricType(
            id: "walkingAsymmetry",
            displayName: "Walking Asymmetry",
            category: .activity,
            quantityIdentifier: .walkingAsymmetryPercentage,
            categoryIdentifier: nil,
            defaultUnit: .percent(),
            unitLabel: "%",
            aggregation: .averageDiscrete,
            icon: "arrow.left.arrow.right",
            color: .purple,
            defaultLineChart: true
        ),

        // Vitals
        HealthMetricType(
            id: "heartRate",
            displayName: "Heart Rate",
            category: .vitals,
            quantityIdentifier: .heartRate,
            categoryIdentifier: nil,
            defaultUnit: HKUnit(from: "count/min"),
            unitLabel: "bpm",
            aggregation: .averageDiscrete,
            icon: "heart.fill",
            color: .red,
            defaultLineChart: true
        ),
        HealthMetricType(
            id: "restingHeartRate",
            displayName: "Resting Heart Rate",
            category: .vitals,
            quantityIdentifier: .restingHeartRate,
            categoryIdentifier: nil,
            defaultUnit: HKUnit(from: "count/min"),
            unitLabel: "bpm",
            aggregation: .averageDiscrete,
            icon: "heart.circle",
            color: .pink,
            defaultLineChart: true
        ),
        HealthMetricType(
            id: "walkingHeartRate",
            displayName: "Walking Heart Rate",
            category: .vitals,
            quantityIdentifier: .walkingHeartRateAverage,
            categoryIdentifier: nil,
            defaultUnit: HKUnit(from: "count/min"),
            unitLabel: "bpm",
            aggregation: .averageDiscrete,
            icon: "figure.walk.motion",
            color: .orange,
            defaultLineChart: true
        ),
        HealthMetricType(
            id: "hrv",
            displayName: "HRV (SDNN)",
            category: .vitals,
            quantityIdentifier: .heartRateVariabilitySDNN,
            categoryIdentifier: nil,
            defaultUnit: HKUnit.secondUnit(with: .milli),
            unitLabel: "ms",
            aggregation: .averageDiscrete,
            icon: "waveform.path.ecg",
            color: .purple,
            defaultLineChart: true
        ),
        HealthMetricType(
            id: "oxygenSaturation",
            displayName: "Blood Oxygen (SpO2)",
            category: .vitals,
            quantityIdentifier: .oxygenSaturation,
            categoryIdentifier: nil,
            defaultUnit: .percent(),
            unitLabel: "%",
            aggregation: .averageDiscrete,
            icon: "drop.fill",
            color: .blue,
            defaultLineChart: true
        ),
        HealthMetricType(
            id: "respiratoryRate",
            displayName: "Respiratory Rate",
            category: .vitals,
            quantityIdentifier: .respiratoryRate,
            categoryIdentifier: nil,
            defaultUnit: HKUnit(from: "count/min"),
            unitLabel: "brpm",
            aggregation: .averageDiscrete,
            icon: "wind",
            color: .teal,
            defaultLineChart: true
        ),
        HealthMetricType(
            id: "wristTemperature",
            displayName: "Sleeping Wrist Temp Deviation",
            category: .vitals,
            quantityIdentifier: .appleSleepingWristTemperature,
            categoryIdentifier: nil,
            defaultUnit: .degreeFahrenheit(),
            unitLabel: "°F",
            aggregation: .averageDiscrete,
            icon: "thermometer.medium",
            color: .yellow,
            defaultLineChart: true
        ),

        // Nutrition
        HealthMetricType(
            id: "dietaryEnergy",
            displayName: "Dietary Energy (Calories)",
            category: .nutrition,
            quantityIdentifier: .dietaryEnergyConsumed,
            categoryIdentifier: nil,
            defaultUnit: .kilocalorie(),
            unitLabel: "kcal",
            aggregation: .cumulativeSum,
            icon: "fork.knife",
            color: .orange,
            defaultLineChart: false
        ),
        HealthMetricType(
            id: "protein",
            displayName: "Dietary Protein",
            category: .nutrition,
            quantityIdentifier: .dietaryProtein,
            categoryIdentifier: nil,
            defaultUnit: .gram(),
            unitLabel: "g",
            aggregation: .cumulativeSum,
            icon: "fish.fill",
            color: .red,
            defaultLineChart: false
        ),
        HealthMetricType(
            id: "fat",
            displayName: "Dietary Fat",
            category: .nutrition,
            quantityIdentifier: .dietaryFatTotal,
            categoryIdentifier: nil,
            defaultUnit: .gram(),
            unitLabel: "g",
            aggregation: .cumulativeSum,
            icon: "drop.triangle.fill",
            color: .yellow,
            defaultLineChart: false
        ),
        HealthMetricType(
            id: "carbohydrates",
            displayName: "Dietary Carbohydrates",
            category: .nutrition,
            quantityIdentifier: .dietaryCarbohydrates,
            categoryIdentifier: nil,
            defaultUnit: .gram(),
            unitLabel: "g",
            aggregation: .cumulativeSum,
            icon: "circle.grid.cross.fill",
            color: .brown,
            defaultLineChart: false
        ),
        HealthMetricType(
            id: "fiber",
            displayName: "Dietary Fiber",
            category: .nutrition,
            quantityIdentifier: .dietaryFiber,
            categoryIdentifier: nil,
            defaultUnit: .gram(),
            unitLabel: "g",
            aggregation: .cumulativeSum,
            icon: "allergens",
            color: .green,
            defaultLineChart: false
        ),
        HealthMetricType(
            id: "sugar",
            displayName: "Dietary Sugar",
            category: .nutrition,
            quantityIdentifier: .dietarySugar,
            categoryIdentifier: nil,
            defaultUnit: .gram(),
            unitLabel: "g",
            aggregation: .cumulativeSum,
            icon: "cube.fill",
            color: .pink,
            defaultLineChart: false
        ),
        HealthMetricType(
            id: "sodium",
            displayName: "Dietary Sodium",
            category: .nutrition,
            quantityIdentifier: .dietarySodium,
            categoryIdentifier: nil,
            defaultUnit: .gramUnit(with: .milli),
            unitLabel: "mg",
            aggregation: .cumulativeSum,
            icon: "circle.hexagongrid.fill",
            color: .gray,
            defaultLineChart: false
        ),
        HealthMetricType(
            id: "water",
            displayName: "Dietary Water",
            category: .nutrition,
            quantityIdentifier: .dietaryWater,
            categoryIdentifier: nil,
            defaultUnit: .fluidOunceUS(),
            unitLabel: "fl oz",
            aggregation: .cumulativeSum,
            icon: "waterbottle.fill",
            color: .blue,
            defaultLineChart: false
        ),
        HealthMetricType(
            id: "caffeine",
            displayName: "Dietary Caffeine",
            category: .nutrition,
            quantityIdentifier: .dietaryCaffeine,
            categoryIdentifier: nil,
            defaultUnit: .gramUnit(with: .milli),
            unitLabel: "mg",
            aggregation: .cumulativeSum,
            icon: "cup.and.saucer.fill",
            color: .brown,
            defaultLineChart: false
        ),

        // Body Measurements
        HealthMetricType(
            id: "bodyMass",
            displayName: "Body Mass (Weight)",
            category: .body,
            quantityIdentifier: .bodyMass,
            categoryIdentifier: nil,
            defaultUnit: .pound(),
            unitLabel: "lbs",
            aggregation: .averageDiscrete,
            icon: "scalemass.fill",
            color: .indigo,
            defaultLineChart: true
        ),
        HealthMetricType(
            id: "bmi",
            displayName: "Body Mass Index (BMI)",
            category: .body,
            quantityIdentifier: .bodyMassIndex,
            categoryIdentifier: nil,
            defaultUnit: .count(),
            unitLabel: "BMI",
            aggregation: .averageDiscrete,
            icon: "person.fill",
            color: .purple,
            defaultLineChart: true
        ),
        HealthMetricType(
            id: "bodyFat",
            displayName: "Body Fat Percentage",
            category: .body,
            quantityIdentifier: .bodyFatPercentage,
            categoryIdentifier: nil,
            defaultUnit: .percent(),
            unitLabel: "%",
            aggregation: .averageDiscrete,
            icon: "percent",
            color: .orange,
            defaultLineChart: true
        ),
        HealthMetricType(
            id: "leanBodyMass",
            displayName: "Lean Body Mass",
            category: .body,
            quantityIdentifier: .leanBodyMass,
            categoryIdentifier: nil,
            defaultUnit: .pound(),
            unitLabel: "lbs",
            aggregation: .averageDiscrete,
            icon: "figure.arms.open",
            color: .mint,
            defaultLineChart: true
        ),
        HealthMetricType(
            id: "waistCircumference",
            displayName: "Waist Circumference",
            category: .body,
            quantityIdentifier: .waistCircumference,
            categoryIdentifier: nil,
            defaultUnit: .inch(),
            unitLabel: "in",
            aggregation: .averageDiscrete,
            icon: "circle.dashed",
            color: .blue,
            defaultLineChart: true
        ),

        // Sleep & Mindfulness
        HealthMetricType(
            id: "sleepDuration",
            displayName: "Time Asleep",
            category: .sleepMindfulness,
            quantityIdentifier: nil,
            categoryIdentifier: .sleepAnalysis,
            defaultUnit: .hour(),
            unitLabel: "hrs",
            aggregation: .cumulativeSum,
            icon: "bed.double.fill",
            color: .indigo,
            defaultLineChart: false
        ),
        HealthMetricType(
            id: "mindfulSession",
            displayName: "Mindful Minutes",
            category: .sleepMindfulness,
            quantityIdentifier: nil,
            categoryIdentifier: .mindfulSession,
            defaultUnit: .minute(),
            unitLabel: "min",
            aggregation: .cumulativeSum,
            icon: "brain.head.profile",
            color: .teal,
            defaultLineChart: false
        )
    ]
}

// MARK: - HealthManager Class
class HealthManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    // Raw samples storage keyed by Metric ID
    @Published var samplesByMetricId: [String: [HKQuantitySample]] = [:]
    // Category samples (Sleep, Mindfulness)
    @Published var categorySamplesByMetricId: [String: [HKCategorySample]] = [:]
    
    // Aggregated Daily Series cache: [MetricID: [Date: Double]]
    @Published var dailySeries: [String: [Date: Double]] = [:]
    
    @Published var isAuthorized: Bool = false
    @Published var isLoading: Bool = false

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device.")
            return
        }

        var readTypes: Set<HKObjectType> = []
        
        for metric in HealthCatalog.allMetrics {
            if let qId = metric.quantityIdentifier,
               let qType = HKObjectType.quantityType(forIdentifier: qId) {
                readTypes.insert(qType)
            } else if let cId = metric.categoryIdentifier,
                      let cType = HKObjectType.categoryType(forIdentifier: cId) {
                readTypes.insert(cType)
            }
        }

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if success {
                    self?.fetchAllData()
                } else if let error = error {
                    print("HealthKit Authorization failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func fetchAllData() {
        DispatchQueue.main.async { self.isLoading = true }
        let group = DispatchGroup()
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: oneYearAgo, end: Date(), options: .strictStartDate)

        var newQuantitySamples: [String: [HKQuantitySample]] = [:]
        var newCategorySamples: [String: [HKCategorySample]] = [:]
        let lock = NSLock()

        for metric in HealthCatalog.allMetrics {
            if let qId = metric.quantityIdentifier,
               let qType = HKObjectType.quantityType(forIdentifier: qId) {
                group.enter()
                let query = HKSampleQuery(sampleType: qType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, _ in
                    let quantitySamples = (samples as? [HKQuantitySample]) ?? []
                    lock.lock()
                    newQuantitySamples[metric.id] = quantitySamples
                    lock.unlock()
                    group.leave()
                }
                healthStore.execute(query)
            } else if let cId = metric.categoryIdentifier,
                      let cType = HKObjectType.categoryType(forIdentifier: cId) {
                group.enter()
                let query = HKSampleQuery(sampleType: cType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, _ in
                    let catSamples = (samples as? [HKCategorySample]) ?? []
                    lock.lock()
                    newCategorySamples[metric.id] = catSamples
                    lock.unlock()
                    group.leave()
                }
                healthStore.execute(query)
            }
        }

        group.notify(queue: .global(qos: .userInitiated)) { [weak self] in
            guard let self = self else { return }
            
            // Build daily aggregated values for every metric
            var newDailySeries: [String: [Date: Double]] = [:]
            let calendar = Calendar.current
            
            for metric in HealthCatalog.allMetrics {
                if let samples = newQuantitySamples[metric.id], !samples.isEmpty {
                    let grouped = Dictionary(grouping: samples) { calendar.startOfDay(for: $0.startDate) }
                    var dayMap: [Date: Double] = [:]
                    for (day, daySamples) in grouped {
                        let values = daySamples.map { $0.quantity.doubleValue(for: metric.defaultUnit) }
                        if metric.aggregation == .cumulativeSum {
                            dayMap[day] = values.reduce(0, +)
                        } else {
                            dayMap[day] = values.isEmpty ? 0 : (values.reduce(0, +) / Double(values.count))
                        }
                    }
                    newDailySeries[metric.id] = dayMap
                } else if let catSamples = newCategorySamples[metric.id], !catSamples.isEmpty {
                    let grouped = Dictionary(grouping: catSamples) { calendar.startOfDay(for: $0.startDate) }
                    var dayMap: [Date: Double] = [:]
                    for (day, daySamples) in grouped {
                        var totalSeconds: Double = 0
                        for s in daySamples {
                            if metric.id == "sleepDuration" {
                                // Only count actual sleep states (asleepUnspecified, core, deep, rem)
                                if #available(iOS 16.0, *) {
                                    if s.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                                       s.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                                       s.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                                       s.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                                        totalSeconds += s.endDate.timeIntervalSince(s.startDate)
                                    }
                                } else {
                                    if s.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                                        totalSeconds += s.endDate.timeIntervalSince(s.startDate)
                                    }
                                }
                            } else {
                                totalSeconds += s.endDate.timeIntervalSince(s.startDate)
                            }
                        }
                        if metric.unitLabel == "hrs" {
                            dayMap[day] = totalSeconds / 3600.0
                        } else if metric.unitLabel == "min" {
                            dayMap[day] = totalSeconds / 60.0
                        } else {
                            dayMap[day] = totalSeconds
                        }
                    }
                    newDailySeries[metric.id] = dayMap
                }
            }

            DispatchQueue.main.async {
                self.samplesByMetricId = newQuantitySamples
                self.categorySamplesByMetricId = newCategorySamples
                self.dailySeries = newDailySeries
                self.isLoading = false
            }
        }
    }

    // Helper for time aggregation
    func aggregateSeries(metric: HealthMetricType, granularity: Calendar.Component) -> [(date: Date, value: Double)] {
        guard let dayData = dailySeries[metric.id], !dayData.isEmpty else { return [] }
        if granularity == .day {
            return dayData.map { (date: $0.key, value: $0.value) }.sorted { $0.date < $1.date }
        }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: dayData.keys) { date -> Date in
            calendar.dateInterval(of: granularity, for: date)?.start ?? date
        }

        var results: [(date: Date, value: Double)] = []
        for (bucketDate, datesInBucket) in grouped {
            let values = datesInBucket.compactMap { dayData[$0] }
            guard !values.isEmpty else { continue }
            let bucketValue: Double
            if metric.aggregation == .cumulativeSum {
                bucketValue = values.reduce(0, +)
            } else {
                bucketValue = values.reduce(0, +) / Double(values.count)
            }
            results.append((date: bucketDate, value: bucketValue))
        }
        return results.sorted { $0.date < $1.date }
    }
}
