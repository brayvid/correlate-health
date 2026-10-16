# Correlate: Apple Health Insights

Correlate is an iOS application designed to help users discover hidden connections and patterns within their personal health data. By integrating directly with Apple HealthKit, the app allows users to compare different health metrics and visualize statistical relationships between them.

---

### Key Features

* **Apple HealthKit Integration:** Seamlessly reads and organizes your personal health data across multiple categories:
  * **Activity:** Step Count, Active Energy
  * **Nutrition:** Dietary Energy, Protein, Fat, Carbohydrates
  * **Vitals:** Heart Rate, Heart Rate Variability (HRV)
  * **Body Measurements:** Body Mass / Weight
* **Metric Correlation Engine:** Select any two health metrics (e.g., *Dietary Fat* vs. *Dietary Energy*, or *Activity* vs. *Resting Heart Rate*) and calculate their statistical **correlation coefficient**.
* **Visual Data Insights:** Generates clean scatter plots to visually plot data points and see trends, clusters, and outliers.
* **Simple Navigation:** Tab-based interface featuring a **Dashboard**, **Insights**, **Correlation Tool**, and **Settings**.

---

### Tech Stack

* **Platform:** iOS
* **Language:** Swift (100%)
* **Frameworks:** HealthKit, SwiftUI / UIKit, Charts/Data Visualization

---

### Directory Structure

```plaintext
correlate-health/
├── correlate-health/
|     ├── CorrelateApp.swift     # App entry point with TabView setup
│     ├── HealthManager.swift    # Handles HealthKit authorization and data
│     ├── ContentView.swift      # Dashboard list of metrics
│     ├── MetricGraphView.swift  # Graph view with time granularity
│     ├── InsightsView.swift     # Placeholder for AI health insights
│     ├── CorrelationView.swift  # Placeholder for metric correlation tool
│     ├── SettingsView.swift     # User settings form
|     ├── Assets.xcassets/       # App icons and assets (Xcode-managed)
|     └── Info.plist             # App configuration and permissions
└── correlate-health.xcodeproj/  # Xcode project file
```

---

### Example Screenshots


<p float="left">
<img src="correlate1.png" style="width:48%">
<img src="correlate2.png" style="width:48%">
</p>

---
<p align="center">&copy; Copyright 2026 <a href="https://blakerayvid.com">Blake Rayvid</a>. All rights reserved.</p>