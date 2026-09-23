import SwiftUI
import UIKit
import WidgetKit

enum PrayerConceptDesign {
    case spotlight
    case almanac
}

enum PrayerConceptFamily {
    case small
    case medium
    case large
}

private enum PrayerConceptPhase: String {
    case fajr, sunrise, dhuhr, asr, maghrib, isha
}

private struct PrayerConceptItem: Identifiable {
    let phase: PrayerConceptPhase
    let name: String
    let time: String
    var id: String {
        phase.rawValue
    }
}

struct PrayerConceptSample {
    let weekday: String
    let dateBadge: String
    let monthYear: String
    let dateLong: String
    let currentName: String
    let currentTime: String
    let currentLabel: String
    fileprivate let currentPhase: PrayerConceptPhase
    let nextName: String
    let nextLabel: String
    let nextTime: String
    fileprivate let nextPhase: PrayerConceptPhase
    let countdown: String
    let compactCountdown: String
    let remainingLabel: String
    let afterName: String
    let afterTime: String
    fileprivate let afterPhase: PrayerConceptPhase
    let scheduleLabel: String
    let prayerTableLabel: String
    let middleNightLabel: String
    let middleNightTime: String
    let lastThirdLabel: String
    let lastThirdTime: String
    fileprivate let schedule: [PrayerConceptItem]
    let isRTL: Bool
    let usesArabicScript: Bool
    let usesArabicNumerals: Bool
    let contentScale: CGFloat
    let countdownStart: Date?
    let countdownTarget: Date?
    let countdownCountsDown: Bool
    let countdownShowsHours: Bool
    let localeIdentifier: String
}

private struct PrayerConceptPalette {
    let background: Color
    let surface: Color
    let raised: Color
    let text: Color
    let secondary: Color
    let accent: Color
    let gold: Color
    let line: Color
    let isLight: Bool
}

private extension Color {
    init(prayerWidgetHex hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

struct PrayerCelestialWidgetView: View {
    let entry: PrayerWidgetEntry
    let family: WidgetFamily

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        let sample = PrayerConceptSample(entry: entry)
        let palette = PrayerConceptPalette(entry: entry, fullColor: renderingMode == .fullColor)
        let conceptFamily = PrayerConceptFamily(widgetFamily: family)
        let design: PrayerConceptDesign = entry.settings.design == .hero ? .spotlight : .almanac

        ZStack {
            PrayerConceptAtmosphere(
                design: design,
                family: conceptFamily,
                palette: palette
            )
            if entry.settings.glassify, renderingMode == .fullColor {
                Color.white.opacity(0.08).allowsHitTesting(false)
            }
            switch design {
            case .spotlight:
                PrayerSpotlightConceptView(
                    family: conceptFamily,
                    sample: sample,
                    palette: palette
                )
            case .almanac:
                PrayerAlmanacConceptView(
                    family: conceptFamily,
                    sample: sample,
                    palette: palette
                )
            }
        }
        .environment(\.layoutDirection, sample.isRTL ? .rightToLeft : .leftToRight)
        .environment(\.locale, Locale(identifier: sample.localeIdentifier))
        .clipShape(ContainerRelativeShape())
        .overlay {
            ContainerRelativeShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            palette.accent.opacity(0.58),
                            palette.text.opacity(0.10),
                            palette.gold.opacity(0.34),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        guard let next = entry.nextPrayer, let date = entry.nextPrayerDate else {
            return PrayerWidgetLocalization.string(
                "empty_message",
                language: entry.settings.effectiveLanguage
            )
        }
        let language = entry.settings.effectiveLanguage
        let name = PrayerWidgetLocalization.prayerName(next, language: language)
        let time = PrayerTimeFormatter.formatDevice(
            date,
            useArabicNumerals: entry.settings.useArabicNumerals,
            languageCode: language,
            format: entry.settings.timeFormat,
            timeZone: entry.settings.displayTimeZone
        )
        return "\(PrayerWidgetLocalization.string(entry.displayedPrayerLabelKey, language: language)): \(name), \(time)"
    }
}

struct PrayerCelestialEmptyWidgetView: View {
    let entry: PrayerWidgetEntry
    let family: WidgetFamily

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        let palette = PrayerConceptPalette(
            entry: entry,
            fullColor: renderingMode == .fullColor
        )
        let conceptFamily = PrayerConceptFamily(widgetFamily: family)
        let design: PrayerConceptDesign = entry.settings.design == .hero
            ? .spotlight
            : .almanac
        let language = entry.settings.effectiveLanguage
        let isRTL = PrayerWidgetLocalization.isRTL(language: language)
        let message = PrayerWidgetLocalization.string(
            "empty_message",
            language: language
        )

        ZStack {
            PrayerConceptAtmosphere(
                design: design,
                family: conceptFamily,
                palette: palette
            )

            if family == .systemSmall {
                VStack(spacing: 11) {
                    PrayerHudaMark(diameter: 31, palette: palette)
                    emptyMessage(message, palette: palette, fontSize: 11)
                }
                .padding(18)
            } else {
                HStack(spacing: family == .systemLarge ? 18 : 14) {
                    PrayerHudaMark(
                        diameter: family == .systemLarge ? 46 : 34,
                        palette: palette
                    )
                    emptyMessage(
                        message,
                        palette: palette,
                        fontSize: family == .systemLarge ? 16 : 13
                    )
                }
                .padding(family == .systemLarge ? 36 : 24)
            }
        }
        .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
        .environment(\.locale, Locale(identifier: language))
        .clipShape(ContainerRelativeShape())
        .overlay {
            ContainerRelativeShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            palette.accent.opacity(0.58),
                            palette.text.opacity(0.10),
                            palette.gold.opacity(0.34),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message)
    }

    private func emptyMessage(
        _ message: String,
        palette: PrayerConceptPalette,
        fontSize: CGFloat
    ) -> some View {
        Text(message)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(palette.text)
            .multilineTextAlignment(.leading)
            .lineLimit(family == .systemSmall ? 4 : 3)
            .minimumScaleFactor(0.65)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension PrayerConceptFamily {
    init(widgetFamily: WidgetFamily) {
        switch widgetFamily {
        case .systemSmall: self = .small
        case .systemLarge: self = .large
        default: self = .medium
        }
    }
}

private extension PrayerConceptPalette {
    init(entry: PrayerWidgetEntry, fullColor: Bool) {
        guard fullColor else {
            self.init(
                background: .primary.opacity(0.10),
                surface: .primary.opacity(0.28),
                raised: .primary.opacity(0.20),
                text: .primary,
                secondary: .secondary,
                accent: .primary,
                gold: .primary,
                line: .primary,
                isLight: false
            )
            return
        }

        let custom = Self.parsedColor(entry.settings.backgroundColor)
        let isLight = custom?.isLight ?? !entry.settings.isDarkMode
        let base: Color
        let surface: Color
        let raised: Color
        if let custom {
            base = custom.color
            surface = custom.color
            raised = custom.color
        } else if entry.settings.backgroundEnabled {
            base = entry.themeColors.gradientStart
            surface = entry.themeColors.gradientEnd
            raised = entry.themeColors.badgeBackground
        } else {
            base = .clear
            surface = .clear
            raised = .clear
        }
        let text = Self.color(from: entry.settings.contentColor) ?? entry.themeColors.textColor
        let accent = Self.color(from: entry.settings.highlightColor) ?? entry.themeColors.accent
        self.init(
            background: base,
            surface: surface,
            raised: raised,
            text: text,
            secondary: text.opacity(isLight ? 0.70 : 0.76),
            accent: accent,
            gold: Color(prayerWidgetHex: isLight ? 0xA9783E : 0xE4C777),
            line: accent,
            isLight: isLight
        )
    }

    static func color(from hex: String?) -> Color? {
        parsedColor(hex)?.color
    }

    static func parsedColor(_ hex: String?) -> (color: Color, isLight: Bool)? {
        guard let raw = hex, !raw.isEmpty else { return nil }
        var cleaned = raw.hasPrefix("#") ? String(raw.dropFirst()) : raw
        if cleaned.count == 6 { cleaned = "FF" + cleaned }
        guard cleaned.count == 8, let value = UInt64(cleaned, radix: 16) else { return nil }
        let alpha = Double((value >> 24) & 0xFF) / 255
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        return (
            Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha),
            luminance >= 0.55
        )
    }
}

private extension PrayerConceptSample {
    init(entry: PrayerWidgetEntry) {
        let language = entry.settings.effectiveLanguage
        let locale = Locale(identifier: language)
        let timeZone = entry.settings.displayTimeZone
        let usesArabicNumerals = entry.settings.useArabicNumerals
        let activeDate = entry.nextPrayerDate ?? entry.date

        func dateString(_ pattern: String, uppercase: Bool = false) -> String {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.timeZone = timeZone
            formatter.dateFormat = pattern
            let value = formatter.string(from: activeDate)
            let cased = uppercase ? value.uppercased(with: locale) : value
            return usesArabicNumerals ? cased.prayerArabicDigits : cased
        }
        func clock(_ date: Date?) -> String {
            guard let date else { return "--:--" }
            return PrayerTimeFormatter.formatDevice(
                date,
                useArabicNumerals: usesArabicNumerals,
                languageCode: language,
                format: entry.settings.timeFormat,
                timeZone: timeZone
            )
        }
        func phase(_ prayer: Prayer?) -> PrayerConceptPhase {
            switch prayer {
            case .fajr: .fajr
            case .sunrise: .sunrise
            case .dhuhr: .dhuhr
            case .asr: .asr
            case .maghrib: .maghrib
            case .isha: .isha
            case nil: .fajr
            }
        }

        let current = (entry.countdownMode == .elapsed
            ? entry.previousPrayer
            : entry.currentPrayer) ?? .isha
        let currentDate = entry.countdownMode == .elapsed
            ? entry.previousPrayerDate
            : entry.currentPrayerDate
        let next = entry.nextPrayer ?? .fajr
        let following = (entry.countdownMode == .elapsed
            ? entry.upcomingPrayer
            : entry.followingPrayer) ?? .dhuhr
        let followingDate = entry.countdownMode == .elapsed
            ? entry.upcomingPrayerDate
            : entry.followingPrayerDate
        let prayerDate = entry.nextPrayerDate
        let timerStart = entry.countdownStartDate
        let timerTarget = entry.countdownTargetDate
        let interval = entry.countdownMode == .elapsed
            ? max(0, entry.date.timeIntervalSince(timerStart ?? entry.date))
            : max(0, (timerTarget ?? entry.date).timeIntervalSince(entry.date))
        let totalSeconds = Int(ceil(interval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        var countdown = String(
            format: "%@%02d:%02d:%02d",
            entry.countdownPrefix,
            hours,
            minutes,
            seconds
        )
        if usesArabicNumerals { countdown = countdown.prayerArabicDigits }

        self.init(
            weekday: dateString("EEEE", uppercase: true),
            dateBadge: dateString("d"),
            monthYear: dateString("MMM · yyyy", uppercase: true),
            dateLong: dateString("EEEE  •  d MMMM yyyy"),
            currentName: PrayerWidgetLocalization.prayerName(current, language: language),
            currentTime: clock(currentDate),
            currentLabel: PrayerWidgetLocalization.string("current", language: language).uppercased(with: locale),
            currentPhase: phase(current),
            nextName: PrayerWidgetLocalization.prayerName(next, language: language),
            nextLabel: PrayerWidgetLocalization.string(entry.displayedPrayerLabelKey, language: language).uppercased(with: locale),
            nextTime: clock(prayerDate),
            nextPhase: phase(next),
            countdown: countdown,
            compactCountdown: countdown,
            remainingLabel: PrayerWidgetLocalization.string(
                entry.countdownMode == .elapsed ? "current" : "remaining",
                language: language
            ).uppercased(with: locale),
            afterName: PrayerWidgetLocalization.prayerName(following, language: language),
            afterTime: clock(followingDate),
            afterPhase: phase(following),
            scheduleLabel: PrayerWidgetLocalization.string("schedule", language: language).uppercased(with: locale),
            prayerTableLabel: PrayerWidgetLocalization.string("prayer_table", language: language).uppercased(with: locale),
            middleNightLabel: PrayerWidgetLocalization.string("middle_of_night", language: language).uppercased(with: locale),
            middleNightTime: clock(entry.middleOfNight),
            lastThirdLabel: PrayerWidgetLocalization.string("last_third_night", language: language).uppercased(with: locale),
            lastThirdTime: clock(entry.lastThirdOfNight),
            schedule: entry.dayPrayers.map { item in
                let (prayer, date) = item
                return PrayerConceptItem(
                    phase: phase(prayer),
                    name: PrayerWidgetLocalization.prayerName(prayer, language: language),
                    time: clock(date)
                )
            },
            isRTL: PrayerWidgetLocalization.isRTL(language: language),
            usesArabicScript: PrayerWidgetLocalization.isRTL(language: language),
            usesArabicNumerals: usesArabicNumerals,
            contentScale: CGFloat(entry.settings.contentSize.clamped(to: 60 ... 140)) / 100,
            countdownStart: timerStart,
            countdownTarget: timerTarget,
            countdownCountsDown: entry.countdownCountsDown,
            countdownShowsHours: entry.countdownShowsHours,
            localeIdentifier: "\(language)-u-nu-\(usesArabicNumerals ? "arab" : "latn")"
        )
    }
}

private extension String {
    var prayerArabicDigits: String {
        let western = Array("0123456789")
        let arabic = Array("٠١٢٣٤٥٦٧٨٩")
        return String(map { character in
            guard let index = western.firstIndex(of: character) else { return character }
            return arabic[index]
        })
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

private struct PrayerConceptAtmosphere: View {
    let design: PrayerConceptDesign
    let family: PrayerConceptFamily
    let palette: PrayerConceptPalette

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: design == .spotlight
                        ? [palette.surface, palette.background, palette.background]
                        : [palette.raised, palette.surface, palette.background],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        palette.accent.opacity(palette.isLight ? 0.16 : 0.24),
                        .clear,
                    ],
                    center: design == .spotlight
                        ? UnitPoint(x: 0.78, y: 0.30)
                        : UnitPoint(x: 0.12, y: 0.04),
                    startRadius: 0,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.72
                )

                RadialGradient(
                    colors: [palette.gold.opacity(0.15), .clear],
                    center: UnitPoint(x: 0.92, y: 0),
                    startRadius: 0,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.42
                )

                Canvas { context, size in
                    if design == .spotlight {
                        var horizon = Path()
                        horizon.move(to: CGPoint(x: -size.width * 0.08, y: size.height * 0.73))
                        horizon.addCurve(
                            to: CGPoint(x: size.width * 1.08, y: size.height * 0.78),
                            control1: CGPoint(x: size.width * 0.24, y: size.height * 0.54),
                            control2: CGPoint(x: size.width * 0.67, y: size.height * 0.56)
                        )
                        context.stroke(
                            horizon,
                            with: .color(palette.accent.opacity(palette.isLight ? 0.16 : 0.12)),
                            style: StrokeStyle(lineWidth: 1, lineCap: .round)
                        )

                        if family != .small {
                            var orbit = Path()
                            orbit.addEllipse(in: CGRect(
                                x: size.width * 0.47,
                                y: -size.height * 0.38,
                                width: size.width * 0.74,
                                height: size.height * 1.10
                            ))
                            context.stroke(
                                orbit,
                                with: .color(palette.gold.opacity(0.075)),
                                lineWidth: 1
                            )
                        }
                    } else {
                        let alpha = palette.isLight ? 0.13 : 0.075
                        var rules = Path()
                        rules.move(to: CGPoint(x: size.width * 0.18, y: 0))
                        rules.addLine(to: CGPoint(x: size.width * 0.18, y: size.height))
                        if family != .small {
                            for index in 0 ..< 4 {
                                let y = size.height * (0.20 + Double(index) * 0.19)
                                rules.move(to: CGPoint(x: 0, y: y))
                                rules.addLine(to: CGPoint(x: size.width, y: y))
                            }
                        }
                        context.stroke(
                            rules,
                            with: .color(palette.gold.opacity(alpha)),
                            lineWidth: 0.75
                        )
                        if family != .small {
                            context.stroke(
                                eightPointStar(
                                    center: CGPoint(x: size.width * 0.96, y: size.height * 0.03),
                                    radius: min(size.width, size.height) * 0.20
                                ),
                                with: .color(palette.gold.opacity(alpha)),
                                lineWidth: 0.8
                            )
                        }
                    }
                }

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .inset(by: 2)
                    .stroke(
                        palette.text.opacity(palette.isLight ? 0.12 : 0.075),
                        lineWidth: 0.7
                    )
            }
        }
    }

    private func eightPointStar(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        let inner = radius * 0.46
        for index in 0 ..< 16 {
            let angle = -Double.pi / 2 + Double(index) * Double.pi / 8
            let r = index.isMultiple(of: 2) ? radius : inner
            let point = CGPoint(
                x: center.x + cos(angle) * r,
                y: center.y + sin(angle) * r
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

private struct PrayerSpotlightConceptView: View {
    let family: PrayerConceptFamily
    let sample: PrayerConceptSample
    let palette: PrayerConceptPalette

    var body: some View {
        switch family {
        case .small: smallLayout
        case .medium: mediumLayout
        case .large: largeLayout
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            PrayerConceptHeader(sample: sample, palette: palette, compact: true)
            Spacer().frame(height: 6)
            Text(sample.nextLabel)
                .font(conceptFont(8, sample: sample, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(palette.secondary)
                .lineLimit(1)
            Text(sample.nextName)
                .font(conceptFont(22, sample: sample, weight: .bold, longSafe: true))
                .foregroundStyle(palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
            Text(sample.nextTime)
                .font(conceptFont(25, sample: sample, weight: .bold, monospaced: true, longSafe: true))
                .foregroundStyle(palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
            Spacer().frame(height: 5)
            PrayerCountdownCapsule(sample: sample, palette: palette, compact: true)
            Spacer(minLength: 2)
            HStack(spacing: 5) {
                PrayerPhaseDot(phase: sample.afterPhase, palette: palette, diameter: 11)
                Text(sample.afterName)
                    .font(conceptFont(9, sample: sample, weight: .medium, longSafe: true))
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text(sample.afterTime)
                    .font(conceptFont(9, sample: sample, weight: .semibold, monospaced: true, longSafe: true))
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
    }

    private var mediumLayout: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                PrayerConceptHeader(sample: sample, palette: palette, compact: true)
                Spacer().frame(height: 7)
                Text(sample.nextLabel)
                    .font(conceptFont(8, sample: sample, weight: .medium))
                    .tracking(0.9)
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
                Text(sample.nextName)
                    .font(conceptFont(25, sample: sample, weight: .bold, longSafe: true))
                    .foregroundStyle(palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
                Text(sample.nextTime)
                    .font(conceptFont(29, sample: sample, weight: .bold, monospaced: true, longSafe: true))
                    .foregroundStyle(palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.64)
                Spacer(minLength: 2)
                PrayerCountdownCapsule(sample: sample, palette: palette)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(palette.text.opacity(0.11))
                .frame(width: 1)

            VStack(spacing: 0) {
                if let item = item(sample.currentPhase) {
                    PrayerSpotlightTimelineRow(
                        item: item,
                        sample: sample,
                        palette: palette,
                        stateLabel: sample.currentLabel
                    )
                }
                PrayerTimelineStem(palette: palette)
                if let item = item(sample.nextPhase) {
                    PrayerSpotlightTimelineRow(
                        item: item,
                        sample: sample,
                        palette: palette,
                        highlighted: true,
                        stateLabel: sample.nextLabel
                    )
                }
                PrayerTimelineStem(palette: palette)
                if let item = item(sample.afterPhase) {
                    PrayerSpotlightTimelineRow(
                        item: item,
                        sample: sample,
                        palette: palette
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            PrayerConceptHeader(sample: sample, palette: palette, compact: false)
            Spacer().frame(height: 13)
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(sample.nextLabel)
                        .font(conceptFont(9, sample: sample, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(palette.secondary)
                        .lineLimit(1)
                    Text(sample.nextName)
                        .font(conceptFont(36, sample: sample, weight: .bold, longSafe: true))
                        .foregroundStyle(palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.56)
                    Text(sample.nextTime)
                        .font(conceptFont(35, sample: sample, weight: .bold, monospaced: true, longSafe: true))
                        .foregroundStyle(palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                }
                Spacer(minLength: 8)
                PrayerCelestialGlyph(phase: sample.nextPhase, palette: palette, diameter: 76)
            }
            Spacer().frame(height: 10)
            PrayerCountdownCapsule(sample: sample, palette: palette, expanded: true)
            Spacer().frame(height: 13)
            Text(sample.scheduleLabel)
                .font(.system(size: 8, weight: .medium))
                .tracking(1)
                .foregroundStyle(palette.secondary)
            Spacer().frame(height: 5)
            VStack(spacing: 5) {
                ForEach(Array(sample.schedule.chunked(into: 2).enumerated()), id: \.offset) { _, pair in
                    HStack(spacing: 8) {
                        ForEach(pair) { item in
                            PrayerSpotlightScheduleCell(
                                item: item,
                                sample: sample,
                                palette: palette
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
    }

    private func item(_ phase: PrayerConceptPhase) -> PrayerConceptItem? {
        if phase == sample.currentPhase {
            return PrayerConceptItem(phase: phase, name: sample.currentName, time: sample.currentTime)
        }
        if phase == sample.nextPhase {
            return PrayerConceptItem(phase: phase, name: sample.nextName, time: sample.nextTime)
        }
        if phase == sample.afterPhase {
            return PrayerConceptItem(phase: phase, name: sample.afterName, time: sample.afterTime)
        }
        if let scheduled = sample.schedule.first(where: { $0.phase == phase }) {
            return scheduled
        }
        return nil
    }
}

private struct PrayerConceptHeader: View {
    let sample: PrayerConceptSample
    let palette: PrayerConceptPalette
    let compact: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            PrayerHudaMark(diameter: compact ? 17 : 20, palette: palette)
            Text(compact ? localizedHuda : sample.dateLong)
                .font(conceptFont(compact ? 8 : 9, sample: sample, weight: .medium))
                .tracking(compact ? 1 : 0.2)
                .foregroundStyle(palette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Spacer(minLength: 5)
            Text("\(sample.currentName.uppercased()) · \(sample.currentLabel)")
                .font(conceptFont(compact ? 7 : 8, sample: sample, weight: .bold, longSafe: true))
                .tracking(0.4)
                .foregroundStyle(palette.gold)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(palette.text.opacity(palette.isLight ? 0.07 : 0.065))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(palette.text.opacity(0.12), lineWidth: 0.6))
        }
    }

    private var localizedHuda: String {
        let locale = Locale(identifier: sample.localeIdentifier)
        return PrayerWidgetLocalization.string(
            "huda",
            language: sample.localeIdentifier
        ).uppercased(with: locale)
    }
}

private struct PrayerCountdownCapsule: View {
    let sample: PrayerConceptSample
    let palette: PrayerConceptPalette
    var compact = false
    var expanded = false

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(palette.gold).frame(width: 5, height: 5)
            Text(sample.remainingLabel)
                .font(conceptFont(expanded ? 9 : compact ? 7 : 8, sample: sample, weight: .medium, longSafe: true))
                .tracking(0.7)
                .foregroundStyle(palette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .layoutPriority(3)
            PrayerLiveCountdownText(sample: sample)
                .font(conceptFont(expanded ? 20 : compact ? 12 : 15, sample: sample, weight: .heavy, monospaced: true, longSafe: true))
                .foregroundStyle(palette.accent)
                .brightness(palette.isLight ? -0.035 : 0.09)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .multilineTextAlignment(countdownTextAlignment)
                .frame(maxWidth: .infinity, alignment: countdownEndAlignment)
                .layoutPriority(2)
        }
        .padding(.horizontal, expanded ? 13 : compact ? 8 : 10)
        .padding(.vertical, expanded ? 9 : compact ? 4 : 6)
        .background(palette.accent.opacity(palette.isLight ? 0.12 : 0.11))
        .clipShape(RoundedRectangle(cornerRadius: expanded ? 16 : 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: expanded ? 16 : 12, style: .continuous)
                .stroke(palette.accent.opacity(palette.isLight ? 0.30 : 0.22), lineWidth: 0.7)
        }
    }

    private var countdownTextAlignment: TextAlignment {
        sample.isRTL ? .leading : .trailing
    }

    private var countdownEndAlignment: Alignment {
        .trailing
    }
}

private struct PrayerLiveCountdownText: View {
    let sample: PrayerConceptSample

    var body: some View {
        if let start = sample.countdownStart,
           let target = sample.countdownTarget,
           target > start
        {
            paddedTimer(start: start, target: target)
                .monospacedDigit()
                .environment(\.locale, countdownTimerLocale)
                .environment(\.layoutDirection, .leftToRight)
        } else {
            Text(sample.countdown)
                .monospacedDigit()
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    private func paddedTimer(start: Date, target: Date) -> Text {
        let prefix = sample.countdownCountsDown ? "−" : "+"
        if sample.countdownShowsHours,
           target.timeIntervalSince(start) < 10 * 60 * 60
        {
            let zero = sample.usesArabicNumerals ? "٠" : "0"
            return Text("\(prefix)\(zero)\(timerInterval: start ... target, countsDown: sample.countdownCountsDown, showsHours: true)")
        }
        return Text("\(prefix)\(timerInterval: start ... target, countsDown: sample.countdownCountsDown, showsHours: sample.countdownShowsHours)")
    }

    private var countdownTimerLocale: Locale {
        Locale(
            identifier: sample.usesArabicNumerals
                ? "en_US_POSIX-u-nu-arab"
                : "en_US_POSIX-u-nu-latn"
        )
    }
}

private struct PrayerSpotlightTimelineRow: View {
    let item: PrayerConceptItem
    let sample: PrayerConceptSample
    let palette: PrayerConceptPalette
    var highlighted = false
    var stateLabel: String?

    var body: some View {
        HStack(spacing: 6) {
            PrayerPhaseDot(
                phase: item.phase,
                palette: palette,
                diameter: 13,
                highlighted: highlighted
            )
            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .font(conceptFont(10, sample: sample, weight: highlighted ? .bold : .medium, longSafe: true))
                    .foregroundStyle(highlighted ? palette.text : palette.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                if let stateLabel {
                    Text(stateLabel)
                        .font(conceptFont(6, sample: sample, weight: .medium, longSafe: true))
                        .tracking(0.5)
                        .foregroundStyle(highlighted ? palette.accent : palette.secondary.opacity(0.66))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 3)
            Text(item.time)
                .font(conceptFont(9, sample: sample, weight: .semibold, monospaced: true, longSafe: true))
                .foregroundStyle(highlighted ? palette.accent : palette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(highlighted ? palette.accent.opacity(0.12) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct PrayerTimelineStem: View {
    let palette: PrayerConceptPalette
    var body: some View {
        Rectangle()
            .fill(palette.line.opacity(0.28))
            .frame(width: 1, height: 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 12)
    }
}

private struct PrayerSpotlightScheduleCell: View {
    let item: PrayerConceptItem
    let sample: PrayerConceptSample
    let palette: PrayerConceptPalette

    var highlighted: Bool {
        item.phase == sample.nextPhase
    }

    var body: some View {
        HStack(spacing: 6) {
            PrayerPhaseDot(
                phase: item.phase,
                palette: palette,
                diameter: 12,
                highlighted: highlighted
            )
            Text(item.name)
                .font(conceptFont(11, sample: sample, weight: highlighted ? .bold : .medium, longSafe: true))
                .foregroundStyle(highlighted ? palette.text : palette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Spacer(minLength: 3)
            Text(item.time)
                .font(conceptFont(10, sample: sample, weight: .semibold, monospaced: true, longSafe: true))
                .foregroundStyle(highlighted ? palette.accent : palette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.64)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(
            highlighted
                ? palette.accent.opacity(0.12)
                : palette.text.opacity(palette.isLight ? 0.045 : 0.055)
        )
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

private struct PrayerAlmanacConceptView: View {
    let family: PrayerConceptFamily
    let sample: PrayerConceptSample
    let palette: PrayerConceptPalette

    var body: some View {
        switch family {
        case .small: smallLayout
        case .medium: mediumLayout
        case .large: largeLayout
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            PrayerAlmanacDateHeader(sample: sample, palette: palette, compact: true)
            Spacer().frame(height: 7)
            PrayerAlmanacNextBand(sample: sample, palette: palette, compact: true)
            Spacer().frame(height: 5)
            ForEach(contextItems) { item in
                PrayerAlmanacRuleRow(item: item, sample: sample, palette: palette)
            }
        }
        .padding(11)
    }

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            PrayerAlmanacDateHeader(sample: sample, palette: palette, compact: true)
            Spacer().frame(height: 5)
            PrayerAlmanacScheduleGrid(
                sample: sample,
                palette: palette,
                compact: true,
                inline: true
            )
            Spacer(minLength: 6)
            PrayerAlmanacNextBand(
                sample: sample,
                palette: palette,
                compact: true,
                wide: true
            )
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
    }

    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            PrayerAlmanacDateHeader(sample: sample, palette: palette, compact: false)
            Spacer().frame(height: 10)
            PrayerAlmanacNextBand(sample: sample, palette: palette, compact: false)
            Spacer().frame(height: 12)
            Text(sample.prayerTableLabel)
                .font(.system(size: 8, weight: .medium))
                .tracking(1.1)
                .foregroundStyle(palette.secondary)
            Spacer().frame(height: 5)
            PrayerAlmanacScheduleGrid(sample: sample, palette: palette, compact: false)
            Spacer().frame(height: 12)
            Rectangle().fill(palette.gold.opacity(0.24)).frame(height: 1)
            Spacer().frame(height: 9)
            HStack(spacing: 10) {
                PrayerNightCell(
                    label: sample.middleNightLabel,
                    time: sample.middleNightTime,
                    iconKind: .middleOfNight,
                    sample: sample,
                    palette: palette
                )
                PrayerNightCell(
                    label: sample.lastThirdLabel,
                    time: sample.lastThirdTime,
                    iconKind: .lastThird,
                    sample: sample,
                    palette: palette
                )
            }
        }
        .padding(16)
    }

    private var contextItems: [PrayerConceptItem] {
        [
            PrayerConceptItem(phase: sample.currentPhase, name: sample.currentName, time: sample.currentTime),
            PrayerConceptItem(phase: sample.nextPhase, name: sample.nextName, time: sample.nextTime),
            PrayerConceptItem(phase: sample.afterPhase, name: sample.afterName, time: sample.afterTime),
        ]
    }
}

private struct PrayerAlmanacDateHeader: View {
    let sample: PrayerConceptSample
    let palette: PrayerConceptPalette
    let compact: Bool

    var body: some View {
        HStack(spacing: compact ? 9 : 13) {
            VStack(spacing: -2) {
                Text(sample.weekday)
                    .font(conceptFont(compact ? 8 : 9, sample: sample, weight: .bold, longSafe: true))
                    .tracking(1)
                    .foregroundStyle(palette.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(sample.dateBadge)
                    .font(conceptFont(compact ? 20 : 34, sample: sample, weight: .bold, editorial: true))
                    .foregroundStyle(palette.text)
                    .lineLimit(1)
            }
            Rectangle()
                .fill(palette.gold.opacity(0.34))
                .frame(width: 1, height: compact ? 30 : 46)
            VStack(alignment: .leading, spacing: 1) {
                Text(sample.monthYear)
                    .font(conceptFont(compact ? 9 : 11, sample: sample, weight: .bold, longSafe: true))
                    .tracking(0.8)
                    .foregroundStyle(palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                Text("\(sample.currentName) · \(sample.currentLabel)")
                    .font(conceptFont(compact ? 8 : 10, sample: sample, weight: .medium, longSafe: true))
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
            }
            Spacer(minLength: 4)
            PrayerHudaMark(diameter: compact ? 17 : 21, palette: palette)
        }
    }
}

private struct PrayerAlmanacNextBand: View {
    let sample: PrayerConceptSample
    let palette: PrayerConceptPalette
    let compact: Bool
    var wide = false

    var body: some View {
        HStack(alignment: .center, spacing: compact && !wide ? 5 : compact ? 6 : 9) {
            PrayerPhaseDot(
                phase: sample.nextPhase,
                palette: palette,
                diameter: compact && !wide ? 12 : compact ? 13 : 18,
                highlighted: true
            )
            VStack(alignment: .leading, spacing: 0) {
                Text(sample.nextLabel)
                    .font(conceptFont(compact ? 7 : 8, sample: sample, weight: .medium, longSafe: true))
                    .tracking(0.7)
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.56)
                if compact, !wide {
                    Text(sample.nextName)
                        .font(conceptFont(12, sample: sample, weight: .bold, editorial: true, longSafe: true))
                        .foregroundStyle(palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.56)
                        .allowsTightening(true)
                    Text(sample.nextTime)
                        .font(conceptFont(11, sample: sample, weight: .bold, monospaced: true, longSafe: true))
                        .foregroundStyle(palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                        .allowsTightening(true)
                        .layoutPriority(2)
                } else {
                    HStack(spacing: 6) {
                        Text(sample.nextName)
                            .font(conceptFont(compact ? 12 : 17, sample: sample, weight: .bold, editorial: true, longSafe: true))
                            .foregroundStyle(palette.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.56)
                        Text(sample.nextTime)
                            .font(conceptFont(compact ? 11 : 16, sample: sample, weight: .bold, monospaced: true, longSafe: true))
                            .foregroundStyle(palette.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                    }
                }
            }
            .layoutPriority(1)
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 0) {
                Text(sample.remainingLabel)
                    .font(conceptFont(compact ? 6 : 7, sample: sample, weight: .medium, longSafe: true))
                    .tracking(0.5)
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .frame(maxWidth: .infinity, alignment: countdownEndAlignment)
                PrayerLiveCountdownText(sample: sample)
                    .font(conceptFont(compact ? 12 : 18, sample: sample, weight: .heavy, monospaced: true, longSafe: true))
                    .foregroundStyle(palette.accent)
                    .brightness(palette.isLight ? -0.035 : 0.09)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .multilineTextAlignment(countdownTextAlignment)
                    .frame(maxWidth: .infinity, alignment: countdownEndAlignment)
            }
            .frame(width: countdownColumnWidth, alignment: countdownEndAlignment)
            .layoutPriority(2)
        }
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 5 : 9)
        .background(palette.accent.opacity(palette.isLight ? 0.11 : 0.10))
        .clipShape(RoundedRectangle(cornerRadius: compact ? 10 : 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: compact ? 10 : 14, style: .continuous)
                .stroke(palette.accent.opacity(0.22), lineWidth: 0.7)
        }
    }

    private var countdownColumnWidth: CGFloat {
        if compact { return wide ? 84 : 56 }
        return 104
    }

    private var countdownEndAlignment: Alignment {
        .trailing
    }

    private var countdownTextAlignment: TextAlignment {
        sample.isRTL ? .leading : .trailing
    }
}

private struct PrayerAlmanacScheduleGrid: View {
    let sample: PrayerConceptSample
    let palette: PrayerConceptPalette
    let compact: Bool
    var inline = false

    var body: some View {
        VStack(spacing: compact ? 3 : 7) {
            ForEach(Array(sample.schedule.chunked(into: 3).enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    ForEach(row) { item in
                        PrayerAlmanacGridCell(
                            item: item,
                            sample: sample,
                            palette: palette,
                            compact: compact,
                            inline: inline
                        )
                    }
                }
            }
        }
    }
}

private struct PrayerAlmanacGridCell: View {
    let item: PrayerConceptItem
    let sample: PrayerConceptSample
    let palette: PrayerConceptPalette
    let compact: Bool
    let inline: Bool

    var highlighted: Bool {
        item.phase == sample.nextPhase
    }

    var sunrise: Bool {
        item.phase == .sunrise
    }

    var body: some View {
        if inline {
            HStack(spacing: 4) {
                PrayerPhaseDot(
                    phase: item.phase,
                    palette: palette,
                    diameter: compact ? 9 : 11,
                    highlighted: highlighted
                )
                Text(item.name)
                    .font(conceptFont(9.5, sample: sample, weight: highlighted ? .bold : .medium, longSafe: true))
                    .foregroundStyle(highlighted ? palette.text : sunrise ? palette.gold : palette.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 2)
                Text(item.time)
                    .font(conceptFont(9.5, sample: sample, weight: .bold, monospaced: true, longSafe: true))
                    .foregroundStyle(highlighted ? palette.accent : palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                    .fixedSize(horizontal: true, vertical: false)
                    .layoutPriority(2)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .prayerAlmanacCellBackground(
                highlighted: highlighted,
                compact: compact,
                palette: palette
            )
        } else {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    PrayerPhaseDot(
                        phase: item.phase,
                        palette: palette,
                        diameter: compact ? 9 : 11,
                        highlighted: highlighted
                    )
                    Text(item.name)
                        .font(conceptFont(compact ? 8 : 11, sample: sample, weight: highlighted ? .bold : .medium, longSafe: true))
                        .foregroundStyle(highlighted ? palette.text : sunrise ? palette.gold : palette.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.48)
                }
                Text(item.time)
                    .font(conceptFont(compact ? 9 : 13, sample: sample, weight: .bold, monospaced: true, longSafe: true))
                    .foregroundStyle(highlighted ? palette.accent : palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, compact ? 6 : 9)
            .padding(.vertical, compact ? 4 : 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .prayerAlmanacCellBackground(
                highlighted: highlighted,
                compact: compact,
                palette: palette
            )
        }
    }
}

private extension View {
    func prayerAlmanacCellBackground(
        highlighted: Bool,
        compact: Bool,
        palette: PrayerConceptPalette
    ) -> some View {
        background(
            highlighted
                ? palette.accent.opacity(0.11)
                : palette.text.opacity(palette.isLight ? 0.035 : 0.045)
        )
        .clipShape(RoundedRectangle(cornerRadius: compact ? 8 : 11, style: .continuous))
    }
}

private struct PrayerAlmanacRuleRow: View {
    let item: PrayerConceptItem
    let sample: PrayerConceptSample
    let palette: PrayerConceptPalette

    var highlighted: Bool {
        item.phase == sample.nextPhase
    }

    var body: some View {
        HStack(spacing: 5) {
            PrayerPhaseDot(
                phase: item.phase,
                palette: palette,
                diameter: 9,
                highlighted: highlighted
            )
            Text(item.name)
                .font(conceptFont(9, sample: sample, weight: highlighted ? .bold : .medium, longSafe: true))
                .foregroundStyle(highlighted ? palette.accent : palette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Spacer(minLength: 4)
            Text(item.time)
                .font(conceptFont(9, sample: sample, weight: .semibold, monospaced: true, longSafe: true))
                .foregroundStyle(highlighted ? palette.accent : palette.text)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}

private struct PrayerNightCell: View {
    let label: String
    let time: String
    let iconKind: PrayerNightIconKind
    let sample: PrayerConceptSample
    let palette: PrayerConceptPalette

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: iconKind.systemName)
                .font(.system(size: 13, weight: .medium))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(palette.gold)
                .frame(width: 18, height: 18)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(conceptFont(8, sample: sample, weight: .medium, longSafe: true))
                    .tracking(0.3)
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.54)
                Text(time)
                    .font(conceptFont(12, sample: sample, weight: .bold, monospaced: true, longSafe: true))
                    .foregroundStyle(palette.text)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.text.opacity(palette.isLight ? 0.04 : 0.05))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

private enum PrayerNightIconKind {
    case middleOfNight
    case lastThird

    var systemName: String {
        switch self {
        case .middleOfNight: "moon.stars.fill"
        case .lastThird: "sunrise.fill"
        }
    }
}

private struct PrayerPhaseDot: View {
    let phase: PrayerConceptPhase
    let palette: PrayerConceptPalette
    let diameter: CGFloat
    var highlighted = false

    var body: some View {
        Image(systemName: legacyPrayerSymbol(for: phase, filled: false))
            .font(.system(
                size: max(7, diameter * 0.76),
                weight: highlighted ? .semibold : .regular
            ))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(
                highlighted
                    ? palette.accent
                    : phase == .sunrise ? palette.gold : palette.secondary
            )
            .frame(width: diameter, height: diameter)
    }
}

private struct PrayerCelestialGlyph: View {
    let phase: PrayerConceptPhase
    let palette: PrayerConceptPalette
    let diameter: CGFloat

    var body: some View {
        Image(systemName: legacyPrayerSymbol(for: phase, filled: true))
            .font(.system(size: diameter * 0.52, weight: .light))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(palette.gold)
            .frame(width: diameter, height: diameter)
    }
}

private func legacyPrayerSymbol(
    for phase: PrayerConceptPhase,
    filled: Bool
) -> String {
    switch phase {
    case .fajr: filled ? "sunrise.fill" : "sunrise"
    case .sunrise: filled ? "sun.horizon.fill" : "sun.horizon"
    case .dhuhr: filled ? "sun.max.fill" : "sun.max"
    case .asr: filled ? "sun.min.fill" : "sun.min"
    case .maghrib: filled ? "sunset.fill" : "sunset"
    case .isha: filled ? "moon.fill" : "moon"
    }
}

private struct PrayerHudaMark: View {
    let diameter: CGFloat
    let palette: PrayerConceptPalette

    private var logo: UIImage? {
        if let image = UIImage(named: "HudaLogo") { return image }
        if let path = Bundle.main.path(forResource: "HudaLogo", ofType: "png") {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }

    var body: some View {
        ZStack {
            Circle().fill(palette.accent.opacity(0.12))
            Circle().stroke(palette.accent.opacity(0.28), lineWidth: 0.6)
            if let logo {
                Image(uiImage: logo)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(palette.text.opacity(0.94))
                    .padding(diameter * 0.17)
            } else {
                Image(systemName: "moon.stars.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(palette.text.opacity(0.94))
                    .padding(diameter * 0.24)
            }
        }
        .frame(width: diameter, height: diameter)
    }
}

private func conceptFont(
    _ base: CGFloat,
    sample: PrayerConceptSample,
    weight: Font.Weight = .regular,
    monospaced: Bool = false,
    editorial: Bool = false,
    longSafe: Bool = false
) -> Font {
    let compensation: CGFloat = longSafe && sample.contentScale > 1 ? 0.82 : 1
    let size = base * sample.contentScale * compensation
    if sample.usesArabicScript || editorial {
        let usesBoldFace = weight == .semibold
            || weight == .bold
            || weight == .heavy
            || weight == .black
        return .custom(usesBoldFace ? "Amiri-Bold" : "Amiri-Regular", size: size)
    }
    return .system(size: size, weight: weight, design: monospaced ? .monospaced : .default)
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
