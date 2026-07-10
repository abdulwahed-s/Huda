import WidgetKit
import SwiftUI

struct PrayerWidgetEntry: TimelineEntry {
    let date: Date
    let settings: PrayerWidgetSettings
    let themeColors: ThemeColors

    let currentPrayer: Prayer?
    let nextPrayer: Prayer?
    let nextPrayerDate: Date?
    let dayPrayers: [(Prayer, Date)]
    let middleOfNight: Date?
    let lastThirdOfNight: Date?
    let isEmptyState: Bool

    static func placeholder(themeColors: ThemeColors, settings: PrayerWidgetSettings) -> PrayerWidgetEntry {
        let now = Date()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now
        return PrayerWidgetEntry(
            date: now,
            settings: settings,
            themeColors: themeColors,
            currentPrayer: .fajr,
            nextPrayer: .dhuhr,
            nextPrayerDate: next,
            dayPrayers: [],
            middleOfNight: nil,
            lastThirdOfNight: nil,
            isEmptyState: false
        )
    }

    static func empty(themeColors: ThemeColors, settings: PrayerWidgetSettings) -> PrayerWidgetEntry {
        return PrayerWidgetEntry(
            date: Date(),
            settings: settings,
            themeColors: themeColors,
            currentPrayer: nil,
            nextPrayer: nil,
            nextPrayerDate: nil,
            dayPrayers: [],
            middleOfNight: nil,
            lastThirdOfNight: nil,
            isEmptyState: true
        )
    }
}

struct PrayerWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> PrayerWidgetEntry {
        let settings = PrayerWidgetDataLoader.loadSettings()
        let theme = WidgetThemeColors.getThemeColors(
            themeName: settings.themeName,
            isDarkMode: settings.isDarkMode
        )
        return PrayerWidgetEntry.placeholder(themeColors: theme, settings: settings)
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerWidgetEntry) -> Void) {
        completion(buildEntries(now: Date()).first ?? placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerWidgetEntry>) -> Void) {
        let now = Date()
        let entries = buildEntries(now: now)
        if entries.isEmpty {
            let fallback = placeholder(in: context)
            let nextRefresh = Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? now
            completion(Timeline(entries: [fallback], policy: .after(nextRefresh)))
            return
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func buildEntries(now: Date) -> [PrayerWidgetEntry] {
        let settings = PrayerWidgetDataLoader.loadSettings()
        let theme = WidgetThemeColors.getThemeColors(
            themeName: settings.themeName,
            isDarkMode: settings.isDarkMode
        )

        guard let coordinates = settings.coordinates else {
            return [PrayerWidgetEntry.empty(themeColors: theme, settings: settings)]
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = settings.displayTimeZone
        let startOfToday = calendar.startOfDay(for: now)
        let allTransitions = PrayerWidgetCalculator.transitions(
            coordinates: coordinates,
            settings: settings,
            startingAt: startOfToday,
            dayCount: 5
        )

        guard !allTransitions.isEmpty else {
            return [PrayerWidgetEntry.empty(themeColors: theme, settings: settings)]
        }

        let todayPrayers: [(Prayer, Date)] = {
            guard let times = PrayerWidgetCalculator.computeTimes(
                coordinates: coordinates,
                date: now,
                settings: settings
            ) else { return [] }
            return PrayerWidgetCalculator.displayMap(from: times)
        }()

        var entries: [PrayerWidgetEntry] = []

        func makeEntry(at activeFrom: Date) -> PrayerWidgetEntry? {
            guard let nextIndex = allTransitions.firstIndex(where: { $0.date > activeFrom }) else {
                return nil
            }
            let nextTransition = allTransitions[nextIndex]
            let currentPrayer: Prayer? = nextIndex > 0 ? allTransitions[nextIndex - 1].prayer : nil

            let activeDayTimes: PrayerTimes? = {
                if calendar.isDate(activeFrom, inSameDayAs: now) {
                    return PrayerWidgetCalculator.computeTimes(
                        coordinates: coordinates,
                        date: now,
                        settings: settings
                    )
                }
                return PrayerWidgetCalculator.computeTimes(
                    coordinates: coordinates,
                    date: activeFrom,
                    settings: settings
                )
            }()

            let dayPrayers: [(Prayer, Date)] = {
                if calendar.isDate(activeFrom, inSameDayAs: now), !todayPrayers.isEmpty {
                    return todayPrayers
                }
                guard let times = activeDayTimes else { return todayPrayers }
                return PrayerWidgetCalculator.displayMap(from: times)
            }()

            let sunnah = activeDayTimes.map { SunnahTimes(from: $0) }

            return PrayerWidgetEntry(
                date: activeFrom,
                settings: settings,
                themeColors: theme,
                currentPrayer: currentPrayer,
                nextPrayer: nextTransition.prayer,
                nextPrayerDate: nextTransition.date,
                dayPrayers: dayPrayers,
                middleOfNight: sunnah?.middleOfTheNight,
                lastThirdOfNight: sunnah?.lastThirdOfTheNight,
                isEmptyState: false
            )
        }

        var activationPoints: [Date] = [now]

        if let immediateNext = allTransitions.first(where: { $0.date > now }) {
            var tick = now.addingTimeInterval(60)
            while tick < immediateNext.date {
                activationPoints.append(tick)
                tick = tick.addingTimeInterval(60)
            }
        }

        for transition in allTransitions where transition.date > now {
            let oneHourBefore = transition.date.addingTimeInterval(-60 * 60)
            if oneHourBefore > now {
                activationPoints.append(oneHourBefore)
            }
            activationPoints.append(transition.date)
        }
        activationPoints.sort()

        var seen = Set<Date>()
        let uniquePoints = activationPoints.filter { seen.insert($0).inserted }

        for at in uniquePoints {
            if let entry = makeEntry(at: at) {
                entries.append(entry)
            }
        }

        return entries
    }
}

struct HudaPrayerWidget: Widget {
    let kind: String = "HudaPrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerWidgetProvider()) { entry in
            PrayerWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    PrayerWidgetBackground(entry: entry)
                }
                .widgetURL(URL(string: "huda://prayer_times"))
        }
        .configurationDisplayName("Huda — Prayer Times")
        .description("Always-on countdown to your next prayer.")
        .supportedFamilies(supportedFamilies)
    }

    private var supportedFamilies: [WidgetFamily] {
        var families: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge]
        #if os(iOS)
        if #available(iOSApplicationExtension 16.0, *) {
            families.append(contentsOf: [
                .accessoryCircular,
                .accessoryRectangular,
                .accessoryInline
            ])
        }
        #endif
        return families
    }
}

struct PrayerWidgetBackground: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        ZStack {
            baseLayer

            if entry.settings.backgroundEnabled
                || parseColor(entry.settings.backgroundColor) != nil
            {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.10),
                        Color.clear,
                        Color.black.opacity(0.04)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private var baseLayer: some View {
        if let custom = parseColor(entry.settings.backgroundColor) {
            ZStack {
                custom
                if entry.settings.glassify {
                    Color.white.opacity(0.08)
                }
            }
        } else if entry.settings.backgroundEnabled {
            LinearGradient(
                colors: [
                    entry.themeColors.gradientStart,
                    entry.themeColors.gradientEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.clear
        }
    }

    private func parseColor(_ hex: String?) -> Color? {
        guard let raw = hex, !raw.isEmpty else { return nil }
        let cleaned = raw.hasPrefix("#") ? String(raw.dropFirst()) : raw
        guard cleaned.count == 8, let value = UInt64(cleaned, radix: 16) else {
            return nil
        }
        let a = Double((value >> 24) & 0xFF) / 255.0
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

struct PrayerWidgetEntryView: View {
    var entry: PrayerWidgetEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        if entry.isEmptyState {
            PrayerWidgetEmptyView(entry: entry, family: widgetFamily)
        } else {
            switch widgetFamily {
            case .accessoryCircular:
                PrayerAccessoryCircularView(entry: entry)
            case .accessoryRectangular:
                PrayerAccessoryRectangularView(entry: entry)
            case .accessoryInline:
                PrayerAccessoryInlineView(entry: entry)
            default:
                switch entry.settings.design {
                case .hero:
                    PrayerHeroWidgetView(entry: entry, family: widgetFamily)
                case .compact:
                    PrayerCompactWidgetView(entry: entry, family: widgetFamily)
                }
            }
        }
    }
}

#Preview(as: .systemMedium) {
    HudaPrayerWidget()
} timeline: {
    PrayerWidgetEntry.placeholder(
        themeColors: WidgetThemeColors.getThemeColors(themeName: "purple", isDarkMode: false),
        settings: PrayerWidgetDataLoader.loadSettings()
    )
}
