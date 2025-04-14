//
//  HealthManager.swift
//  Correlate
//
//  Created by Blake Rayvid on 4/12/25.
import Foundation
import HealthKit

class HealthManager: ObservableObject {
    private var healthStore = HKHealthStore()

    @Published var steps: [HKQuantitySample] = []
    @Published var activeEnergy: [HKQuantitySample] = []
    @Published var dietaryEnergy: [HKQuantitySample] = []
    @Published var protein: [HKQuantitySample] = []
    @Published var fat: [HKQuantitySample] = []
    @Published var carbohydrates: [HKQuantitySample] = []
    @Published var heartRate: [HKQuantitySample] = []
    @Published var hrv: [HKQuantitySample] = []
    @Published var bodyMass: [HKQuantitySample] = []
    @Published var bmi: [HKQuantitySample] = []
    @Published var sleep: [HKQuantitySample] = []

    func requestAuthorization() {
        let identifiers: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .activeEnergyBurned,
            .dietaryEnergyConsumed, // ← Add this line
            .dietaryProtein,
            .dietaryFatTotal,
            .dietaryCarbohydrates,
            .heartRate,
            .heartRateVariabilitySDNN,
            .bodyMass,
            .bodyMassIndex,
            .appleSleepingWristTemperature
        ]


        let typesToRead: Set = Set(identifiers.compactMap {
            HKObjectType.quantityType(forIdentifier: $0)
        })

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                self.fetchAllData()
            } else if let error = error {
                print("Authorization failed: \(error.localizedDescription)")
            }
        }
    }

    func fetchAllData() {
        fetchSamples(for: .stepCount) { self.updateOnMainThread(\HealthManager.steps, with: $0) }
        fetchSamples(for: .activeEnergyBurned) { self.updateOnMainThread(\HealthManager.activeEnergy, with: $0) }
        fetchSamples(for: .dietaryEnergyConsumed) { self.updateOnMainThread(\HealthManager.dietaryEnergy, with: $0)}
        fetchSamples(for: .dietaryProtein) { self.updateOnMainThread(\HealthManager.protein, with: $0) }
        fetchSamples(for: .dietaryFatTotal) { self.updateOnMainThread(\HealthManager.fat, with: $0) }
        fetchSamples(for: .dietaryCarbohydrates) { self.updateOnMainThread(\HealthManager.carbohydrates, with: $0) }
        fetchSamples(for: .heartRate) { self.updateOnMainThread(\HealthManager.heartRate, with: $0) }
        fetchSamples(for: .heartRateVariabilitySDNN) { self.updateOnMainThread(\HealthManager.hrv, with: $0) }
        fetchSamples(for: .bodyMass) { self.updateOnMainThread(\HealthManager.bodyMass, with: $0) }
        fetchSamples(for: .bodyMassIndex) { self.updateOnMainThread(\HealthManager.bmi, with: $0) }
        fetchSamples(for: .appleSleepingWristTemperature) { self.updateOnMainThread(\HealthManager.sleep, with: $0) }
    }

    private func fetchSamples(for identifier: HKQuantityTypeIdentifier, completion: @escaping ([HKQuantitySample]) -> Void) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            completion([])
            return
        }

        let start = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: [])

        let query = HKSampleQuery(
            sampleType: quantityType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, _ in
            let quantitySamples = samples as? [HKQuantitySample] ?? []
            completion(quantitySamples)
        }

        healthStore.execute(query)
    }

    func average(samples: [HKQuantitySample], by component: Calendar.Component, using unit: HKUnit) -> [(date: Date, value: Double)] {
        let grouped = Dictionary(grouping: samples) { sample in
            let calendar = Calendar.current
            let components: DateComponents

            switch component {
            case .day:
                components = calendar.dateComponents([.year, .month, .day], from: sample.startDate)
            case .weekOfYear:
                components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: sample.startDate)
            case .month:
                components = calendar.dateComponents([.year, .month], from: sample.startDate)
            case .year:
                components = calendar.dateComponents([.year], from: sample.startDate)
            default:
                components = calendar.dateComponents([.year, .month, .day], from: sample.startDate)
            }

            return calendar.date(from: components) ?? sample.startDate
        }

        return grouped.map { (date, samples) in
            let total = samples.reduce(0.0) { sum, sample in
                sum + sample.quantity.doubleValue(for: unit)
            }
            let average = total / Double(samples.count)
            return (date, average)
        }
        .sorted { $0.date < $1.date }
    }

    private func updateOnMainThread(_ keyPath: ReferenceWritableKeyPath<HealthManager, [HKQuantitySample]>, with samples: [HKQuantitySample]) {
        DispatchQueue.main.async {
            self[keyPath: keyPath] = samples
        }
    }
}
