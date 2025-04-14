//
//  SettingsView.swift
//  Correlate
//
//  Created by Blake Rayvid on 4/12/25.
//
import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Privacy")) {
                    Toggle("Store data locally only", isOn: .constant(true))
                }
                Section(header: Text("Goals")) {
                    Text("Set step, calorie, and protein goals here.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
