import SwiftUI
import WidgetKit

struct PrayerWidgetEntry: TimelineEntry {
    let date: Date
    let settings: PrayerWidgetSettings
    let themeColors: ThemeColors

    let currentPrayer: Prayer?
    let currentPrayerDate: Date?
    let previousPrayer: Prayer?
    let previousPrayerDate: Date?
    let upcomingPrayer: Prayer?
    let upcomingPrayerDate: Date?
    let followingPrayer: Prayer?
    let followingPrayerDate: Date?
    let dayPrayers: [(Prayer, Date)]
    let middleOfNight: Date?
    let lastThirdOfNight: Date?
    let countdownMode: PrayerWidgetCountdownMode
    let countdownStateEnd: Date?
    let isEmptyState: Bool

    var nextPrayer: Prayer? {
        countdownMode == .elapsed ? currentPrayer : upcomingPrayer
    }

    var nextPrayerDate: Date? {
        countdownMode == .elapsed ? currentPrayerDate : upcomingPrayerDate
    }

    var displayedPrayer: Prayer? {
        nextPrayer
    }

    var displayedPrayerDate: Date? {
        nextPrayerDate
    }

    var countdownStartDate: Date? {
        countdownMode == .elapsed ? currentPrayerDate : date
    }

    var countdownTargetDate: Date? {
        countdownMode == .elapsed ? countdownStateEnd : upcomingPrayerDate
    }

    var countdownCountsDown: Bool {
        countdownMode == .countdown
    }

    var countdownPrefix: String {
        countdownCountsDown ? "−" : "+"
    }

    var countdownShowsHours: Bool {
        guard countdownCountsDown,
              let target = countdownTargetDate else { return false }
        return target.timeIntervalSince(date) >= 60 * 60
    }

    var displayedPrayerLabelKey: String {
        countdownMode == .elapsed ? "current" : "next_prayer"
    }

    static func placeholder(themeColors: ThemeColors, settings: PrayerWidgetSettings) -> PrayerWidgetEntry {
        let now = Date()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = settings.displayTimeZone
        let startOfDay = calendar.startOfDay(for: now)
        func time(_ hour: Int, _ minute: Int) -> Date {
            calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: startOfDay
            ) ?? now
        }

        let fajr = time(4, 36)
        let sunrise = time(5, 51)
        let dhuhr = time(12, 8)
        let asr = time(15, 33)
        let maghrib = time(18, 24)
        let isha = time(19, 39)
        return PrayerWidgetEntry(
            date: time(17, 5),
            settings: settings,
            themeColors: themeColors,
            currentPrayer: .asr,
            currentPrayerDate: asr,
            previousPrayer: .dhuhr,
            previousPrayerDate: dhuhr,
            upcomingPrayer: .maghrib,
            upcomingPrayerDate: maghrib,
            followingPrayer: .isha,
            followingPrayerDate: isha,
            dayPrayers: [
                (.fajr, fajr),
                (.sunrise, sunrise),
                (.dhuhr, dhuhr),
                (.asr, asr),
                (.maghrib, maghrib),
                (.isha, isha),
            ],
            middleOfNight: nil,
            lastThirdOfNight: nil,
            countdownMode: .countdown,
            countdownStateEnd: maghrib,
            isEmptyState: false
        )
    }

    static func empty(themeColors: ThemeColors, settings: PrayerWidgetSettings) -> PrayerWidgetEntry {
        PrayerWidgetEntry(
            date: Date(),
            settings: settings,
            themeColors: themeColors,
            currentPrayer: nil,
            currentPrayerDate: nil,
            previousPrayer: nil,
            previousPrayerDate: nil,
            upcomingPrayer: nil,
            upcomingPrayerDate: nil,
            followingPrayer: nil,
            followingPrayerDate: nil,
            dayPrayers: [],
            middleOfNight: nil,
            lastThirdOfNight: nil,
            countdownMode: .countdown,
            countdownStateEnd: nil,
            isEmptyState: true
        )
    }
}

struct PrayerWidgetProvider: TimelineProvider {
    private static let timelineHorizon: TimeInterval = 7 * 24 * 60 * 60
    private static let reloadInterval: TimeInterval = 12 * 60 * 60
    private static let maximumEntryCount = 120

    func placeholder(in _: Context) -> PrayerWidgetEntry {
        let settings = PrayerWidgetDataLoader.loadSettings()
        let theme = WidgetThemeColors.getThemeColors(
            themeName: settings.themeName,
            isDarkMode: settings.isDarkMode
        )
        return PrayerWidgetEntry.placeholder(themeColors: theme, settings: settings)
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerWidgetEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        completion(
            buildEntries(now: Date(), maximumEntries: 1).first
                ?? placeholder(in: context)
        )
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<PrayerWidgetEntry>) -> Void) {
        let now = Date()
        let entries = buildEntries(now: now, maximumEntries: Self.maximumEntryCount)
        if entries.isEmpty || entries.allSatisfy(\.isEmptyState) {
            let settings = PrayerWidgetDataLoader.loadSettings()
            let theme = WidgetThemeColors.getThemeColors(
                themeName: settings.themeName,
                isDarkMode: settings.isDarkMode
            )
            let fallback = PrayerWidgetEntry.empty(themeColors: theme, settings: settings)
            let nextRefresh = now.addingTimeInterval(60 * 60)
            completion(Timeline(entries: [fallback], policy: .after(nextRefresh)))
            return
        }
        completion(Timeline(
            entries: entries,
            policy: .after(now.addingTimeInterval(Self.reloadInterval))
        ))
    }

    private func buildEntries(now: Date, maximumEntries: Int) -> [PrayerWidgetEntry] {
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
        let transitionStart = calendar.date(byAdding: .day, value: -1, to: startOfToday)
            ?? startOfToday
        let allTransitions = PrayerWidgetCalculator.transitions(
            coordinates: coordinates,
            settings: settings,
            startingAt: transitionStart,
            dayCount: 10
        )

        guard !allTransitions.isEmpty else {
            return [PrayerWidgetEntry.empty(themeColors: theme, settings: settings)]
        }

        var entries: [PrayerWidgetEntry] = []
        let resolverTransitions = allTransitions.map {
            PrayerWidgetTransition(prayer: $0.prayer, date: $0.date)
        }
        var timesByDay: [Date: PrayerWidgetDayTimes] = [:]

        func cachedTimes(for date: Date) -> PrayerWidgetDayTimes? {
            let day = calendar.startOfDay(for: date)
            if let cached = timesByDay[day] {
                return cached
            }
            guard let computed = PrayerWidgetCalculator.computeTimes(
                coordinates: coordinates,
                date: day,
                settings: settings
            ) else {
                return nil
            }
            timesByDay[day] = computed
            return computed
        }

        func makeEntry(at activeFrom: Date) -> PrayerWidgetEntry? {
            guard let moment = PrayerWidgetStateResolver.resolve(
                now: activeFrom,
                transitions: resolverTransitions
            ) else { return nil }
            let currentTransition = moment.latestStartedIndex.map {
                resolverTransitions[$0]
            }
            let previousTransition = moment.latestStartedIndex.flatMap {
                resolverTransitions.indices.contains($0 - 1)
                    ? resolverTransitions[$0 - 1]
                    : nil
            }
            let nextTransition = moment.nextIndex.map {
                resolverTransitions[$0]
            }
            let followingTransition = moment.nextIndex.flatMap {
                resolverTransitions.indices.contains($0 + 1)
                    ? resolverTransitions[$0 + 1]
                    : nil
            }

            let activeDayTimes = cachedTimes(for: moment.prayerDate)

            let dayPrayers: [(Prayer, Date)] = {
                guard let times = activeDayTimes else { return [] }
                return PrayerWidgetCalculator.displayMap(from: times)
            }()

            let civilTimes = cachedTimes(for: activeFrom)
            let nightAnchor: Date = {
                guard let fajr = civilTimes?.fajr, activeFrom < fajr else {
                    return activeFrom
                }
                return calendar.date(byAdding: .day, value: -1, to: activeFrom)
                    ?? activeFrom
            }()
            let sunnah = PrayerWidgetCalculator.sunnahTimes(
                coordinates: coordinates,
                settings: settings,
                date: nightAnchor
            )

            return PrayerWidgetEntry(
                date: activeFrom,
                settings: settings,
                themeColors: theme,
                currentPrayer: currentTransition?.prayer,
                currentPrayerDate: currentTransition?.date,
                previousPrayer: previousTransition?.prayer,
                previousPrayerDate: previousTransition?.date,
                upcomingPrayer: nextTransition?.prayer,
                upcomingPrayerDate: nextTransition?.date,
                followingPrayer: followingTransition?.prayer,
                followingPrayerDate: followingTransition?.date,
                dayPrayers: dayPrayers,
                middleOfNight: sunnah.middle,
                lastThirdOfNight: sunnah.lastThird,
                countdownMode: moment.mode,
                countdownStateEnd: moment.stateEnd,
                isEmptyState: false
            )
        }

        let horizon = now.addingTimeInterval(Self.timelineHorizon)
        let uniquePoints = PrayerWidgetStateResolver.activationPoints(
            now: now,
            through: horizon,
            transitions: resolverTransitions
        )

        for at in uniquePoints.prefix(max(1, maximumEntries)) {
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
                .prayerWidgetContainerBackground {
                    PrayerWidgetFamilyBackground(entry: entry)
                }
                .widgetURL(URL(string: "huda://prayer_times"))
        }
        .configurationDisplayName("Huda — Prayer Times")
        .description("Prayer times and the next prayer at a glance.")
        .supportedFamilies(supportedFamilies)
    }

    private var supportedFamilies: [WidgetFamily] {
        var families: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge]
        #if os(iOS)
            if #available(iOSApplicationExtension 16.0, *) {
                families.append(contentsOf: [
                    .accessoryCircular,
                    .accessoryInline,
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
                        Color.black.opacity(0.04),
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
                    entry.themeColors.gradientEnd,
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

private struct PrayerWidgetFamilyBackground: View {
    let entry: PrayerWidgetEntry

    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            if renderingMode == .fullColor {
                PrayerWidgetBackground(entry: entry)
                    .clipShape(Circle())
                    .padding(1)
            } else {
                // Lock Screen accessories are rendered as a vibrant mask. Keep
                // the themed artwork out of that mask so it cannot become a
                // bright, opaque shape after system processing.
                Color.clear
            }
        case .accessoryInline:
            Color.clear
        default:
            PrayerWidgetBackground(entry: entry)
                .clipShape(ContainerRelativeShape())
        }
    }
}

struct PrayerWidgetEntryView: View {
    var entry: PrayerWidgetEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        if entry.isEmptyState {
            switch widgetFamily {
            case .accessoryCircular, .accessoryRectangular, .accessoryInline:
                PrayerWidgetEmptyView(entry: entry, family: widgetFamily)
            default:
                PrayerCelestialEmptyWidgetView(entry: entry, family: widgetFamily)
            }
        } else {
            switch widgetFamily {
            case .accessoryCircular:
                PrayerAccessoryCircularView(entry: entry)
            case .accessoryRectangular:
                PrayerAccessoryRectangularView(entry: entry, segment: .early)
            case .accessoryInline:
                PrayerAccessoryInlineView(entry: entry)
            default:
                PrayerCelestialWidgetView(entry: entry, family: widgetFamily)
            }
        }
    }
}

struct HudaEarlyPrayerTimesWidget: Widget {
    let kind = "HudaEarlyPrayerTimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerWidgetProvider()) { entry in
            PrayerAccessoryScheduleEntryView(entry: entry, segment: .early)
                .prayerWidgetContainerBackground {
                    PrayerAccessoryContainerBackground(entry: entry)
                }
                .widgetURL(URL(string: "huda://prayer_times"))
        }
        .configurationDisplayName("Huda — Fajr to Dhuhr")
        .description("Fajr, Shurooq, and Dhuhr in a compact three-row schedule.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct HudaLatePrayerTimesWidget: Widget {
    let kind = "HudaLatePrayerTimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerWidgetProvider()) { entry in
            PrayerAccessoryScheduleEntryView(entry: entry, segment: .late)
                .prayerWidgetContainerBackground {
                    PrayerAccessoryContainerBackground(entry: entry)
                }
                .widgetURL(URL(string: "huda://prayer_times"))
        }
        .configurationDisplayName("Huda — Asr to Isha")
        .description("Asr, Maghrib, and Isha in a compact three-row schedule.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct HudaPrayerPathWidget: Widget {
    let kind = "HudaPrayerPathWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerWidgetProvider()) { entry in
            PrayerAccessoryPathEntryView(entry: entry)
                .prayerWidgetContainerBackground {
                    PrayerAccessoryContainerBackground(entry: entry)
                }
                .widgetURL(URL(string: "huda://prayer_times"))
        }
        .configurationDisplayName("Huda — Today's Path")
        .description("The current, next, and following prayers with a live countdown.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct HudaPrayerAlmanacWidget: Widget {
    let kind = "HudaPrayerAlmanacWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerWidgetProvider()) { entry in
            PrayerAccessoryAlmanacEntryView(entry: entry)
                .prayerWidgetContainerBackground {
                    PrayerAccessoryContainerBackground(entry: entry)
                }
                .widgetURL(URL(string: "huda://prayer_times"))
        }
        .configurationDisplayName("Huda — Prayer Almanac")
        .description("The date, next prayer, prayer time, and a live countdown.")
        .supportedFamilies([.accessoryRectangular])
    }
}

private extension View {
    @ViewBuilder
    func prayerWidgetContainerBackground(
        @ViewBuilder background: () -> some View
    ) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget, content: background)
        } else {
            self.background(background())
        }
    }
}

/// Keeps decorative artwork in WidgetKit's removable background layer. Lock
/// Screen accessories use `.vibrant`, while tinted/clear widgets use
/// `.accented`; neither mode should receive a full-size foreground color mask.
private struct PrayerAccessoryContainerBackground: View {
    let entry: PrayerWidgetEntry

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        switch renderingMode {
        case .fullColor:
            PrayerWidgetBackground(entry: entry)
                .clipShape(ContainerRelativeShape())
        case .accented, .vibrant:
            Color.clear
        default:
            Color.clear
        }
    }
}

private struct PrayerAccessoryScheduleEntryView: View {
    let entry: PrayerWidgetEntry
    let segment: PrayerAccessoryScheduleSegment

    var body: some View {
        PrayerAccessoryPanel {
            if entry.isEmptyState {
                PrayerWidgetEmptyView(entry: entry, family: .accessoryRectangular)
            } else {
                PrayerAccessoryRectangularView(entry: entry, segment: segment)
            }
        }
    }
}

private struct PrayerAccessoryPathEntryView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        PrayerAccessoryPanel {
            if entry.isEmptyState {
                PrayerWidgetEmptyView(entry: entry, family: .accessoryRectangular)
            } else {
                PrayerAccessoryPathView(entry: entry)
            }
        }
    }
}

private struct PrayerAccessoryAlmanacEntryView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        PrayerAccessoryPanel {
            if entry.isEmptyState {
                PrayerWidgetEmptyView(entry: entry, family: .accessoryRectangular)
            } else {
                PrayerAccessoryAlmanacView(entry: entry)
            }
        }
    }
}

private struct PrayerAccessoryPanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        // WidgetKit supplies context-appropriate content margins. There must be
        // no full-size foreground fill here: in `.vibrant` it would be converted
        // into the nearly opaque white material seen in the Lock Screen failure.
        content
            .padding(.horizontal, 2)
    }
}
