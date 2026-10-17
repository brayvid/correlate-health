# Correlate: Apple Health Insights

Correlate is an iOS application designed to help users discover hidden connections and patterns within their personal health data. By integrating directly with Apple HealthKit, the app allows users to track over 25 health metrics, compute mathematical derivatives (rates of change) and time lags, visualize trends with Swift Charts, and run an automated statistical discovery engine that surfaces significant cross-metric correlations.

---

### Key Features

* **Comprehensive HealthKit Catalog:** Reads and organizes 25+ health data streams across all major wellness domains:
  * **Activity & Mobility:** Step Count, Active Calories, Basal Energy, Walking/Running Distance, Flights Climbed, Exercise Time, Stand Time, Walking Speed, Walking Step Length, Walking Asymmetry.
  * **Vitals & Heart:** Heart Rate, Resting Heart Rate, Walking Heart Rate Average, Heart Rate Variability (SDNN), Blood Oxygen (SpO2), Respiratory Rate, Sleeping Wrist Temperature Deviation.
  * **Nutrition:** Dietary Calories, Protein, Total Fat, Carbohydrates, Dietary Fiber, Sugar, Sodium, Water, Caffeine.
  * **Body Measurements:** Body Mass (Weight), Body Mass Index (BMI), Body Fat Percentage, Lean Body Mass, Waist Circumference.
  * **Sleep & Mindfulness:** Time Asleep (Core, Deep, REM stages), Mindful Session Minutes.
* **Unified Swift Charts Experience:** Responsive, modern charts built with Apple's native Swift Charts framework:
  * Dynamic time granularities (Daily, Weekly, Monthly).
  * Multiple display styles (Smooth Spline, Line + Points, Bar, and Gradient Area).
  * Auto-calibrated Y/X axes tightly fit to the observed data domain (no forced origin/zero baseline).
  * Statistical summary cards (Latest, Average, Min, Max) and reference rule lines.
* **Mathematical Time-Series Transformations:**
  * **Linear Interpolation:** Seamlessly fills gaps between intermittent discrete measurements (e.g. scale weigh-ins and vital checks) to enable continuous trajectories and valid multi-day rates of change.
  * **Derivatives / Rates of Change (Delta):** First numerical derivatives (1-day change, 7-day velocity) to identify velocities and rate-of-change patterns (e.g., day-over-day weight shifts, weekly body mass velocity, resting heart rate spikes).
  * **Temporal Lags (t - k):** Shifted time series (1, 2, 3, or 7 days ago) to track delayed physiological reactions (e.g., Yesterday's Sleep Duration vs. Today's Resting Heart Rate).
* **Automated Correlation Discovery Engine (AI Insights):**
  * Automatically cross-correlates combinations of active raw, derivative, and lagged features.
  * Evaluates Pearson correlation coefficients (r) and validates sample sizes.
  * Prunes trivial and tautological relationships (e.g., Steps vs. Distance, Weight vs. BMI, Calories vs. Fat) to highlight authentic bio-energetic discoveries.
  * Specialized interpretations for Body Mass Velocity, distinguishing short-term water/glycogen shifts from sustained caloric energy balance.
  * Drill-down scatter plots with best-fit linear regression lines and custom coordinate scales.
* **Deep Search & Flexible Filtering:**
  * Interactive autocomplete search selector allowing instant filtering by metric name or exact feature transform (e.g., `Body Mass [7-Day Delta]`).
  * Independent multi-category toggles to isolate or combine **Raw**, **Rates of Change (Delta)**, and **Lagged** features.
  * Polarity filter to separate positive and inverse correlations.
  * Multi-metric sorting by correlation magnitude (|r|), X-axis, or Y-axis.
* **Bivariate Correlation Tool:** Interactively compare any two metrics or transformed features against one another with linear regression trendlines and sample counts.

---

### Tech Stack

* **Platform:** iOS 16.0+ (Optimized for iOS 18+)
* **Language:** Swift 5
* **Frameworks:** HealthKit, SwiftUI, Swift Charts, Foundation
* **Architecture:** MVVM with reactive Combine publishers (@Published, @EnvironmentObject)

---

### Directory Structure

```plaintext
correlate-health/
├── README.md
├── Storyboard.storyboard
├── correlate-health.xcodeproj/
│   ├── project.pbxproj
│   └── project.xcworkspace/
│       └── contents.xcworkspacedata
└── correlate-health/
    ├── CorrelateApp.swift            # App entry point with TabView navigation setup
    ├── HealthManager.swift           # HealthKit authorization, data ingestion & catalog (25+ metrics)
    ├── TimeSeriesTransforms.swift     # Mathematical engine for interpolation, derivatives, and lags
    ├── ContentView.swift             # Categorized Health Dashboard with latest values
    ├── MetricGraphView.swift         # Unified Swift Charts view with axes, styles & transforms
    ├── CorrelationView.swift         # Bivariate correlation tool with scatter plot & regression
    ├── InsightsView.swift            # Automated correlation engine with search, toggles & scatter drill-down
    ├── SettingsView.swift            # User settings & privacy configurations
    ├── Info.plist                    # App configuration and HealthKit permissions
    ├── correlate-health.entitlements # HealthKit capability entitlements
    └── Assets.xcassets/              # App icons, colors, and asset catalogs
        ├── Contents.json
        ├── AccentColor.colorset/
        │   └── Contents.json
        └── AppIcon.appiconset/
            ├── Contents.json
            └── icon.jpg
```

---

### Example Screenshots

<p float="left">
<img src="example1.png" style="width:48%">
<img src="example2.png" style="width:48%">
</p>

---
<p align="center">&copy; Copyright 2026 <a href="https://blakerayvid.com">Blake Rayvid</a>. All rights reserved.</p>