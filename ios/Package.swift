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
            path: "HudaWidget",
            exclude: [
                "Amiri-Bold.ttf",
                "Amiri-Regular.ttf",
                "AppIntent.swift",
                "Assets.xcassets",
                "HudaPrayerWidget.swift",
                "HudaWidget.swift",
                "HudaWidgetBundle.swift",
                "Info.plist",
                "PrayerTimePlus/PrayerTimePlus.docc",
                "PrayerWidgetCelestialViews.swift",
                "PrayerWidgetViews.swift",
                "WidgetDataLoader.swift",
                "WidgetThemeColors.swift",
            ],
            sources: [
                "PrayerTimePlus",
                "PrayerWidgetCalculator.swift",
                "PrayerWidgetDataLoader.swift",
                "PrayerWidgetLocalization.swift",
                "PrayerWidgetStateResolver.swift",
            ]
        ),
        .testTarget(
            name: "HudaWidgetLogicTests",
            dependencies: ["HudaWidgetLogic"],
            path: "HudaWidgetTests"
        ),
    ]
)
