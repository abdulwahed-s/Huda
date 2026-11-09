// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HudaWidgetLogic",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "HudaWidgetLogic", targets: ["HudaWidgetLogic"]),
    ],
    targets: [
        .target(
            name: "HudaWidgetLogic",
            path: ".",
            exclude: [
                "Runner", "RunnerTests", "Runner.xcodeproj", "Runner.xcworkspace",
                "HudaWidgetTests", "HudaShield", "HudaShieldAction", "HudaDeviceMonitor",
                "Flutter", "Pods", "Podfile", "Podfile.lock", "fastlane",
                "HudaWidgetExtension.entitlements",
                "HudaWidget/Amiri-Bold.ttf", "HudaWidget/Amiri-Regular.ttf",
                "HudaWidget/AppIntent.swift", "HudaWidget/Assets.xcassets",
                "HudaWidget/HudaPrayerWidget.swift", "HudaWidget/HudaWidget.swift",
                "HudaWidget/HudaWidgetBundle.swift", "HudaWidget/Info.plist",
                "HudaWidget/PrayerTimePlus/PrayerTimePlus.docc",
                "HudaWidget/PrayerWidgetCelestialViews.swift", "HudaWidget/PrayerWidgetViews.swift",
                "HudaWidget/WidgetDataLoader.swift", "HudaWidget/WidgetThemeColors.swift",
            ],
            sources: [
                "HudaWidget/PrayerTimePlus", "SharedPrayer/IOSPrayerCore.swift", "SharedPrayer/IOSPrayerPolicy.swift", "SharedPrayer/IOSPrayerStore.swift", "SharedPrayer/IOSPrayerBackgroundDiagnostics.swift",
                "HudaWidget/PrayerWidgetCalculator.swift", "HudaWidget/PrayerWidgetDataLoader.swift",
                "HudaWidget/PrayerWidgetLocalization.swift", "HudaWidget/PrayerWidgetStateResolver.swift",
            ]
        ),
        .testTarget(
            name: "HudaWidgetLogicTests",
            dependencies: ["HudaWidgetLogic"],
            path: "HudaWidgetTests"
        ),
    ]
)
