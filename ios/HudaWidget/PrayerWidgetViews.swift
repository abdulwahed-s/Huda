import WidgetKit
import SwiftUI

private extension PrayerWidgetEntry {
    var language: String { settings.effectiveLanguage }
    var arabicNumerals: Bool { settings.useArabicNumerals }
    var contentScale: CGFloat { CGFloat(settings.contentSize) / 100.0 }

    var resolvedTextColor: Color {
        if let custom = PrayerWidgetEntry.parseColor(settings.contentColor) {
            return custom
        }
        return themeColors.textColor
    }

    var resolvedSecondaryColor: Color {
        if let custom = PrayerWidgetEntry.parseColor(settings.contentColor) {
            return custom.opacity(0.7)
        }
        return themeColors.secondaryTextColor
    }

    var resolvedAccent: Color {
        if let custom = PrayerWidgetEntry.parseColor(settings.highlightColor) {
            return custom
        }
        return themeColors.accent
    }

    static func parseColor(_ hex: String?) -> Color? {
        guard let raw = hex, !raw.isEmpty else { return nil }
        let cleaned = raw.hasPrefix("#") ? String(raw.dropFirst()) : raw
        guard cleaned.count == 8, let value = UInt64(cleaned, radix: 16) else { return nil }
        let a = Double((value >> 24) & 0xFF) / 255.0
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

struct PrayerWidgetEmptyView: View {
    let entry: PrayerWidgetEntry
    let family: WidgetFamily

    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    var body: some View {
        let palette = PrayerAccessoryPalette(
            entry: entry,
            renderingMode: renderingMode,
            isLuminanceReduced: isLuminanceReduced,
            colorSchemeContrast: colorSchemeContrast
        )

        VStack(spacing: 8) {
            Image(systemName: "location.slash")
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(palette.indicator)

            Text(PrayerWidgetLocalization.string(
                "empty_message",
                language: entry.language
            ))
            .font(.system(size: messageFontSize, weight: .semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(palette.primary)
            .lineLimit(4)
            .minimumScaleFactor(0.7)
        }
        .padding(12)
        .environment(\.layoutDirection,
                     PrayerWidgetLocalization.isRTL(language: entry.language) ? .rightToLeft : .leftToRight)
    }

    private var iconSize: CGFloat {
        switch family {
        case .systemSmall: return 28
        case .systemMedium: return 32
        case .systemLarge: return 44
        case .accessoryCircular: return 18
        default: return 28
        }
    }

    private var messageFontSize: CGFloat {
        switch family {
        case .systemSmall: return 11
        case .systemMedium: return 13
        case .systemLarge: return 16
        case .accessoryRectangular: return 11
        default: return 12
        }
    }
}

struct PrayerHeroWidgetView: View {
    let entry: PrayerWidgetEntry
    let family: WidgetFamily

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallLayout
            case .systemMedium:
                mediumLayout
            case .systemLarge:
                largeLayout
            default:
                mediumLayout
            }
        }
        .environment(\.layoutDirection,
                     PrayerWidgetLocalization.isRTL(language: entry.language) ? .rightToLeft : .leftToRight)
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(PrayerWidgetLocalization.string("next_prayer",
                                                 language: entry.language))
                .font(.system(size: 11 * entry.contentScale, weight: .medium))
                .foregroundColor(entry.resolvedSecondaryColor)
                .lineLimit(1)

            if let next = entry.nextPrayer {
                Text(PrayerWidgetLocalization.prayerName(next, language: entry.language))
                    .font(.system(size: 18 * entry.contentScale, weight: .bold, design: .rounded))
                    .foregroundColor(entry.resolvedTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            if let target = entry.nextPrayerDate {
                Text(PrayerTimeFormatter.format(
                    target,
                    useArabicNumerals: entry.arabicNumerals,
                    timeZone: entry.settings.displayTimeZone
                ))
                    .font(.system(size: 22 * entry.contentScale, weight: .bold, design: .rounded))
                    .foregroundColor(entry.resolvedTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .monospacedDigit()
            }

            compactCountdownText(fontSize: 16)

            Spacer(minLength: 0)

            Rectangle()
                .fill(entry.resolvedTextColor.opacity(0.15))
                .frame(height: 1)
                .padding(.bottom, 4)

            VStack(spacing: 2) {
                ForEach(Array(smallUpcomingPrayers.enumerated()), id: \.offset) { _, item in
                    let (prayer, date) = item
                    HStack {
                        Text(PrayerWidgetLocalization.prayerName(prayer, language: entry.language))
                            .font(.system(size: 11 * entry.contentScale, weight: .regular))
                            .foregroundColor(entry.resolvedSecondaryColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer(minLength: 4)
                        Text(PrayerTimeFormatter.format(
                            date,
                            useArabicNumerals: entry.arabicNumerals,
                            timeZone: entry.settings.displayTimeZone
                        ))
                            .font(.system(size: 11 * entry.contentScale, weight: .semibold, design: .rounded))
                            .foregroundColor(entry.resolvedSecondaryColor)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var smallUpcomingPrayers: [(Prayer, Date)] {
        guard let next = entry.nextPrayer else { return [] }
        let all = entry.dayPrayers
        guard let idx = all.firstIndex(where: { $0.0 == next }) else { return [] }
        return Array(all.dropFirst(idx + 1).prefix(3))
    }

    private var mediumLayout: some View {
        HStack(alignment: .center, spacing: 14) {
            mediumHeroBlock
                .frame(maxWidth: .infinity, alignment: .leading)

            listView(showIcon: false,
                     rowSpacing: 3,
                     nameSize: 12,
                     timeSize: 12,
                     highlightInset: 6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var mediumHeroBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(PrayerWidgetLocalization.string("next_prayer",
                                                 language: entry.language))
                .font(.system(size: 11 * entry.contentScale, weight: .medium))
                .foregroundColor(entry.resolvedSecondaryColor)
                .lineLimit(1)

            if let next = entry.nextPrayer {
                Text(PrayerWidgetLocalization.prayerName(next,
                                                         language: entry.language))
                    .font(.system(size: 22 * entry.contentScale,
                                  weight: .bold,
                                  design: .rounded))
                    .foregroundColor(entry.resolvedTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            if let target = entry.nextPrayerDate {
                Text(PrayerTimeFormatter.format(
                    target,
                    useArabicNumerals: entry.arabicNumerals,
                    timeZone: entry.settings.displayTimeZone
                ))
                    .font(.system(size: 32 * entry.contentScale,
                                  weight: .heavy,
                                  design: .rounded))
                    .foregroundColor(entry.resolvedTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .monospacedDigit()
            }

            HStack(spacing: 3) {
                Text(PrayerWidgetLocalization.string("in_word",
                                                     language: entry.language))
                    .font(.system(size: 11 * entry.contentScale, weight: .medium))
                    .foregroundColor(entry.resolvedSecondaryColor)
                compactCountdownText(fontSize: 11)
                Spacer(minLength: 0)
            }
        }
    }

    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            largeInnerCard

            listView(showIcon: true,
                     rowSpacing: 6,
                     nameSize: 15,
                     timeSize: 15,
                     highlightInset: 8)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var largeInnerCard: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let next = entry.nextPrayer {
                    Text(PrayerWidgetLocalization.prayerName(next,
                                                             language: entry.language))
                        .font(.system(size: 15 * entry.contentScale,
                                      weight: .medium))
                        .foregroundColor(entry.resolvedSecondaryColor)
                        .lineLimit(1)
                }

                if let target = entry.nextPrayerDate {
                    Text(PrayerTimeFormatter.format(
                        target,
                        useArabicNumerals: entry.arabicNumerals,
                        timeZone: entry.settings.displayTimeZone
                    ))
                        .font(.system(size: 48 * entry.contentScale,
                                      weight: .heavy,
                                      design: .rounded))
                        .foregroundColor(entry.resolvedTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .monospacedDigit()
                }

                HStack(spacing: 3) {
                    Text(PrayerWidgetLocalization.string("next_prayer",
                                                         language: entry.language))
                        .font(.system(size: 12 * entry.contentScale, weight: .medium))
                        .foregroundColor(entry.resolvedSecondaryColor)
                    Text(PrayerWidgetLocalization.string("in_word",
                                                         language: entry.language))
                        .font(.system(size: 12 * entry.contentScale, weight: .medium))
                        .foregroundColor(entry.resolvedSecondaryColor)
                    compactCountdownText(fontSize: 12)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)

            heroIcon
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(entry.resolvedAccent.opacity(0.12))
        )
    }

    @ViewBuilder
    private func compactCountdownText(fontSize: CGFloat) -> some View {
        if let target = entry.nextPrayerDate, target > entry.date {
            prayerCountdownTimerText(
                start: entry.date,
                target: target,
                useArabicNumerals: entry.arabicNumerals
            )
                .font(.system(size: fontSize * entry.contentScale, weight: .medium))
                .foregroundColor(entry.resolvedSecondaryColor)
                .monospacedDigit()
                .environment(
                    \.locale,
                    prayerCountdownTimerLocale(useArabicNumerals: entry.arabicNumerals)
                )
        }
    }

    private var heroIcon: some View {
        let systemName: String = {
            guard let next = entry.nextPrayer else { return "sunrise.fill" }
            return Self.iconName(for: next, filled: true)
        }()
        return Image(systemName: systemName)
            .font(.system(size: 36 * entry.contentScale, weight: .light))
            .foregroundColor(entry.resolvedSecondaryColor)
            .symbolRenderingMode(.hierarchical)
    }

    private func listView(showIcon: Bool,
                          rowSpacing: CGFloat,
                          nameSize: CGFloat,
                          timeSize: CGFloat,
                          highlightInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: rowSpacing) {
            ForEach(Array(entry.dayPrayers.enumerated()), id: \.offset) { _, item in
                let (prayer, date) = item
                let isNext = entry.nextPrayer == prayer
                row(prayer: prayer,
                    date: date,
                    isNext: isNext,
                    showIcon: showIcon,
                    nameSize: nameSize,
                    timeSize: timeSize,
                    highlightInset: highlightInset)
            }
        }
    }

    private func row(prayer: Prayer,
                     date: Date,
                     isNext: Bool,
                     showIcon: Bool,
                     nameSize: CGFloat,
                     timeSize: CGFloat,
                     highlightInset: CGFloat) -> some View {
        let primary = isNext ? entry.resolvedTextColor : entry.resolvedSecondaryColor
        let weight: Font.Weight = isNext ? .semibold : .regular

        let content = HStack(spacing: showIcon ? 10 : 6) {
            if showIcon {
                Image(systemName: Self.iconName(for: prayer, filled: false))
                    .font(.system(size: nameSize * entry.contentScale,
                                  weight: .regular))
                    .foregroundColor(primary)
                    .frame(width: (nameSize + 4) * entry.contentScale,
                           alignment: .center)
            }
            Text(PrayerWidgetLocalization.prayerName(prayer,
                                                     language: entry.language))
                .font(.system(size: nameSize * entry.contentScale,
                              weight: weight))
                .foregroundColor(primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 4)
            Text(PrayerTimeFormatter.format(
                date,
                useArabicNumerals: entry.arabicNumerals,
                timeZone: entry.settings.displayTimeZone
            ))
                .font(.system(size: timeSize * entry.contentScale,
                              weight: weight,
                              design: .rounded))
                .foregroundColor(primary)
                .monospacedDigit()
                .lineLimit(1)
        }
        .padding(.horizontal, highlightInset)
        .padding(.vertical, max(2, highlightInset - 4))

        return content
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isNext ? entry.resolvedAccent.opacity(0.15) : Color.clear)
            )
    }

    static func iconName(for prayer: Prayer, filled: Bool) -> String {
        switch prayer {
        case .fajr:     return filled ? "sunrise.fill"     : "sunrise"
        case .sunrise:  return filled ? "sun.horizon.fill" : "sun.horizon"
        case .dhuhr:    return filled ? "sun.max.fill"     : "sun.max"
        case .asr:      return filled ? "sun.min.fill"     : "sun.min"
        case .maghrib:  return filled ? "sunset.fill"      : "sunset"
        case .isha:     return filled ? "moon.fill"        : "moon"
        }
    }
}

private enum ArabicTatweel {
    private static let connectors: Set<Character> = [
        "ب", "ت", "ث", "ج", "ح", "خ",
        "س", "ش", "ص", "ض", "ط", "ظ",
        "ع", "غ", "ف", "ق", "ك", "ل",
        "م", "ن", "ه", "ي", "ئ", "ـ"
    ]

    static func elongate(_ text: String, count: Int) -> String {
        guard count > 0 else { return text }
        var result = ""
        let chars = Array(text)
        for (index, ch) in chars.enumerated() {
            result.append(ch)
            guard index + 1 < chars.count else { continue }
            let next = chars[index + 1]
            if connectors.contains(ch) && next.isLetter {
                for _ in 0..<count { result.append("ـ") }
            }
        }
        return result
    }
}

struct PrayerCompactWidgetView: View {
    let entry: PrayerWidgetEntry
    let family: WidgetFamily

    private static let classicHighlight = Color(red: 208.0/255.0, green: 64.0/255.0, blue: 52.0/255.0)

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallLayout
            case .systemMedium:
                mediumLayout
            case .systemLarge:
                largeLayout
            default:
                mediumLayout
            }
        }
        .environment(\.layoutDirection,
                     PrayerWidgetLocalization.isRTL(language: entry.language) ? .rightToLeft : .leftToRight)
    }

    private var primaryText: Color {
        if let custom = PrayerWidgetEntry.parseColor(entry.settings.contentColor) {
            return custom
        }
        return entry.themeColors.textColor
    }

    private var secondaryText: Color {
        if let custom = PrayerWidgetEntry.parseColor(entry.settings.contentColor) {
            return custom.opacity(0.6)
        }
        return entry.themeColors.secondaryTextColor
    }

    private var highlight: Color {
        if let custom = PrayerWidgetEntry.parseColor(entry.settings.highlightColor) {
            return custom
        }
        return entry.themeColors.accent
    }

    private func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let lang = PrayerWidgetLocalization.canonicalKey(entry.language)
        let isArabicScript = (lang == "ar" || lang == "ur")
        let opticalScale: CGFloat = {
            guard isArabicScript else { return 1.0 }
            return family == .systemLarge ? 1.15 : 1.3
        }()
        let scaled = size * entry.contentScale * opticalScale
        if isArabicScript {
            let face = arabicFontName(for: weight)
            return Font.custom(face, size: scaled)
        }
        return .system(size: scaled, weight: weight, design: .serif)
    }

    private func arabicFontName(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light, .regular, .medium:
            return "Amiri-Regular"
        default:
            return "Amiri-Bold"
        }
    }

    private var isoDate: String {
        PrayerTimeFormatter.formatISODate(entry.date,
                                          useArabicNumerals: entry.arabicNumerals,
                                          timeZone: entry.settings.displayTimeZone)
    }

    private var dayOfWeek: String {
        PrayerTimeFormatter.formatDayOfWeek(entry.date,
                                            languageCode: entry.language,
                                            timeZone: entry.settings.displayTimeZone)
    }

    private func time12WithMeridiem(_ date: Date) -> String {
        PrayerTimeFormatter.format12WithMeridiem(
            date,
            useArabicNumerals: entry.arabicNumerals,
            languageCode: entry.language,
            timeZone: entry.settings.displayTimeZone
        )
    }

    private func time12(_ date: Date) -> String {
        PrayerTimeFormatter.format12(
            date,
            useArabicNumerals: entry.arabicNumerals,
            timeZone: entry.settings.displayTimeZone
        )
    }

    private var smallLayout: some View {
        let lang = PrayerWidgetLocalization.canonicalKey(entry.language)
        let isArabicScript = (lang == "ar" || lang == "ur")
        let displayedDay: String = isArabicScript
            ? ArabicTatweel.elongate(dayOfWeek, count: 1)
            : dayOfWeek
        let vSpacing: CGFloat = isArabicScript ? -10 : 4
        return VStack(alignment: .center, spacing: vSpacing) {
            Text(isoDate)
                .font(serif(11, weight: .bold))
                .foregroundColor(primaryText)
                .monospacedDigit()

            Text(displayedDay)
                .font(serif(32, weight: .bold))
                .foregroundColor(primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .center)

            if let next = entry.nextPrayer {
                Text(PrayerWidgetLocalization.prayerName(next, language: entry.language))
                    .font(serif(20, weight: .bold))
                    .foregroundColor(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            if let target = entry.nextPrayerDate {
                Text(time12WithMeridiem(target))
                    .font(serif(26, weight: .bold))
                    .foregroundColor(primaryText)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            if let target = entry.nextPrayerDate, target > entry.date {
                prayerCountdownTimerText(
                    start: entry.date,
                    target: target,
                    useArabicNumerals: entry.arabicNumerals
                )
                    .font(serif(18, weight: .bold))
                    .foregroundColor(primaryText)
                    .monospacedDigit()
                    .environment(
                        \.locale,
                        prayerCountdownTimerLocale(useArabicNumerals: entry.arabicNumerals)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(.center)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(isoDate)
                .font(serif(11, weight: .bold))
                .foregroundColor(primaryText)
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .center)

            mediumDayName

            mediumPrayerStrip

            Spacer(minLength: 0)

            Rectangle()
                .fill(highlight.opacity(0.20))
                .frame(height: 0.5)
                .padding(.vertical, 2)

            mediumCountdownLine
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var mediumDayName: some View {
        let lang = PrayerWidgetLocalization.canonicalKey(entry.language)
        let isArabicScript = (lang == "ar" || lang == "ur")
        let displayed: String = {
            guard isArabicScript else { return dayOfWeek }
            return ArabicTatweel.elongate(dayOfWeek, count: 2)
        }()
        return Text(displayed)
            .font(serif(isArabicScript ? 40 : 48, weight: .bold))
            .foregroundColor(primaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var mediumPrayerStrip: some View {
        let prayers = entry.dayPrayers.filter { $0.0 != .sunrise }
        return HStack(alignment: .top, spacing: 6) {
            ForEach(Array(prayers.enumerated()), id: \.offset) { _, item in
                let (prayer, date) = item
                let isNext = entry.nextPrayer == prayer
                VStack(spacing: 2) {
                    Text(PrayerWidgetLocalization.prayerName(prayer,
                                                             language: entry.language))
                        .font(serif(16, weight: .bold))
                        .foregroundColor(isNext ? highlight : primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(time12(date))
                        .font(serif(16, weight: .bold))
                        .foregroundColor(isNext ? highlight : primaryText)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var mediumCountdownLine: some View {
        HStack(spacing: 4) {
            if let next = entry.nextPrayer {
                Text(PrayerWidgetLocalization.string("remaining_until",
                                                     language: entry.language))
                    .font(serif(13, weight: .semibold))
                    .foregroundColor(highlight)
                Text(PrayerWidgetLocalization.prayerName(next,
                                                         language: entry.language))
                    .font(serif(13, weight: .bold))
                    .foregroundColor(highlight)
            }
            Spacer(minLength: 6)
            if let target = entry.nextPrayerDate, target > entry.date {
                prayerCountdownTimerText(
                    start: entry.date,
                    target: target,
                    useArabicNumerals: entry.arabicNumerals
                )
                    .font(serif(13, weight: .bold))
                    .foregroundColor(highlight)
                    .monospacedDigit()
                    .environment(
                        \.locale,
                        prayerCountdownTimerLocale(useArabicNumerals: entry.arabicNumerals)
                    )
                    .lineLimit(1)
            }
        }
    }

    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(isoDate)
                    .font(serif(12, weight: .bold))
                    .foregroundColor(primaryText)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .fixedSize(horizontal: false, vertical: true)

                largeDayName
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            largeHeroPill

            largePrayerGrid

            Rectangle()
                .fill(highlight.opacity(0.20))
                .frame(height: 0.5)
                .padding(.vertical, 2)

            largeSunnahRow

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var largeDayName: some View {
        let lang = PrayerWidgetLocalization.canonicalKey(entry.language)
        let isArabicScript = (lang == "ar" || lang == "ur")
        let displayed: String = isArabicScript
            ? ArabicTatweel.elongate(dayOfWeek, count: 2)
            : dayOfWeek

        if isArabicScript {
            Text(displayed)
                .font(serif(30, weight: .bold))
                .foregroundColor(primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 56)
                .clipped()
        } else {
            Text(displayed)
                .font(serif(56, weight: .bold))
                .foregroundColor(primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var largeHeroPill: some View {
        HStack(alignment: .center, spacing: 12) {
            if let target = entry.nextPrayerDate, target > entry.date {
                prayerCountdownTimerText(
                    start: entry.date,
                    target: target,
                    useArabicNumerals: entry.arabicNumerals
                )
                    .font(serif(22, weight: .regular))
                    .foregroundColor(primaryText)
                    .monospacedDigit()
                    .environment(
                        \.locale,
                        prayerCountdownTimerLocale(useArabicNumerals: entry.arabicNumerals)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            Spacer(minLength: 0)

            if let next = entry.nextPrayer, let target = entry.nextPrayerDate {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(PrayerWidgetLocalization.prayerName(next,
                                                             language: entry.language))
                        .font(serif(18, weight: .bold))
                        .foregroundColor(primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(time12WithMeridiem(target))
                        .font(serif(18, weight: .bold))
                        .foregroundColor(primaryText)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(highlight.opacity(0.12))
        )
    }

    private var largePrayerGrid: some View {
        let items = entry.dayPrayers
        let rows: [[(Prayer, Date)]] = [
            Array(items.prefix(3)),
            Array(items.suffix(from: min(items.count, 3)))
        ]
        return VStack(spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .top, spacing: 10) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, item in
                        let (prayer, date) = item
                        let isNext = entry.nextPrayer == prayer
                        gridCell(prayer: prayer,
                                 date: date,
                                 highlighted: isNext)
                            .frame(maxWidth: .infinity)
                    }
                    if row.count < 3 {
                        ForEach(0..<(3 - row.count), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    private func gridCell(prayer: Prayer, date: Date, highlighted: Bool) -> some View {
        VStack(spacing: 3) {
            Text(PrayerWidgetLocalization.prayerName(prayer, language: entry.language))
                .font(serif(20, weight: .bold))
                .foregroundColor(highlighted ? highlight : primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(time12(date))
                .font(serif(20, weight: .bold))
                .foregroundColor(highlighted ? highlight : primaryText)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }

    private var largeSunnahRow: some View {
        HStack(alignment: .top, spacing: 10) {
            sunnahCell(
                title: PrayerWidgetLocalization.string("last_third_night",
                                                       language: entry.language),
                date: entry.lastThirdOfNight
            )
            sunnahCell(
                title: PrayerWidgetLocalization.string("middle_of_night",
                                                       language: entry.language),
                date: entry.middleOfNight
            )
        }
    }

    private func sunnahCell(title: String, date: Date?) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(serif(15, weight: .bold))
                .foregroundColor(primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(date.map(time12) ?? "—")
                .font(serif(17, weight: .bold))
                .foregroundColor(primaryText)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AdaptiveCountdownText: View {
    let entry: PrayerWidgetEntry
    let target: Date
    let font: Font
    var compact: Bool = false

    private static let oneHour: TimeInterval = 60 * 60

    var body: some View {
        if target.timeIntervalSince(entry.date) >= Self.oneHour {
            Text(staticText)
                .font(font)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        } else if target > entry.date {
            Text(timerInterval: entry.date...target, countsDown: true)
                .font(font)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        } else {
            Text("--:--")
                .font(font)
                .monospacedDigit()
        }
    }

    private var staticText: String {
        if compact {
            return Self.formatHHMM(
                from: entry.date,
                to: target,
                useArabicNumerals: entry.arabicNumerals
            )
        }
        return PrayerTimeFormatter.formatCompactRelative(
            from: entry.date,
            to: target,
            useArabicNumerals: entry.arabicNumerals,
            languageCode: entry.language
        )
    }

    private static func formatHHMM(
        from start: Date,
        to end: Date,
        useArabicNumerals: Bool
    ) -> String {
        let interval = max(0, end.timeIntervalSince(start))
        let totalMinutes = Int((interval / 60).rounded(.up))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: useArabicNumerals ? "ar" : "en_US_POSIX")
        formatter.minimumIntegerDigits = 2
        formatter.maximumIntegerDigits = 2
        formatter.usesGroupingSeparator = false

        let h = formatter.string(from: NSNumber(value: hours)) ?? "00"
        let m = formatter.string(from: NSNumber(value: minutes)) ?? "00"
        return "\(h):\(m)"
    }
}

private func prayerCountdownTimerText(
    start: Date,
    target: Date,
    useArabicNumerals: Bool,
    prefix: String = ""
) -> Text {
    if target.timeIntervalSince(start) < 10 * 60 * 60 {
        let zero = useArabicNumerals ? "٠" : "0"
        return Text("\(prefix)\(zero)\(timerInterval: start...target, countsDown: true, showsHours: true)")
    }
    return Text("\(prefix)\(timerInterval: start...target, countsDown: true, showsHours: true)")
}

private func prayerCountdownTimerLocale(useArabicNumerals: Bool) -> Locale {
    Locale(
        identifier: useArabicNumerals
            ? "en_US_POSIX-u-nu-arab"
            : "en_US_POSIX-u-nu-latn"
    )
}

private func progressStart(for entry: PrayerWidgetEntry) -> Date? {
    guard let target = entry.nextPrayerDate else { return nil }
    if let current = entry.currentPrayer,
       let date = entry.dayPrayers.first(where: { $0.0 == current })?.1,
       date < target {
        return date
    }
    return target.addingTimeInterval(-6 * 60 * 60)
}

struct PrayerAccessoryCircularView: View {
    let entry: PrayerWidgetEntry

    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    var body: some View {
        let palette = PrayerAccessoryPalette(
            entry: entry,
            renderingMode: renderingMode,
            isLuminanceReduced: isLuminanceReduced,
            colorSchemeContrast: colorSchemeContrast
        )

        ZStack {
            AccessoryWidgetBackground()

            if let target = entry.nextPrayerDate,
               let start = progressStart(for: entry),
               target > entry.date {
                ProgressView(
                    timerInterval: start...target,
                    countsDown: false,
                    label: { EmptyView() },
                    currentValueLabel: {
                        VStack(spacing: 0) {
                            if let next = entry.nextPrayer {
                                Text(PrayerWidgetLocalization
                                        .prayerName(next, language: entry.language))
                                    .font(.system(size: 10, weight: .semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            AdaptiveCountdownText(
                                entry: entry,
                                target: target,
                                font: .system(size: 11, weight: .bold, design: .rounded),
                                compact: true
                            )
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 2)
                    }
                )
                .progressViewStyle(.circular)
                .widgetAccentable()
            } else if let next = entry.nextPrayer {
                VStack(spacing: 0) {
                    Text(PrayerWidgetLocalization.prayerName(next, language: entry.language))
                        .font(.system(size: 10, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text("--:--")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
            } else {
                Image(systemName: "moon.stars.fill")
            }
        }
        .foregroundStyle(palette.primary)
        .environment(\.layoutDirection,
                     PrayerWidgetLocalization.isRTL(language: entry.language) ? .rightToLeft : .leftToRight)
    }
}

enum PrayerAccessoryScheduleSegment {
    case early
    case late

    var prayers: [Prayer] {
        switch self {
        case .early:
            return [.fajr, .sunrise, .dhuhr]
        case .late:
            return [.asr, .maghrib, .isha]
        }
    }
}

/// Source colors for the system widget-rendering pipeline. Vibrant rendering
/// derives material brightness from source luminance, so those values are
/// deliberately opaque grayscale rather than translucent white.
private struct PrayerAccessoryPalette {
    let primary: Color
    let secondary: Color
    let divider: Color
    let indicator: Color
    let badgeBackground: Color

    init(
        entry: PrayerWidgetEntry,
        renderingMode: WidgetRenderingMode,
        isLuminanceReduced: Bool,
        colorSchemeContrast: ColorSchemeContrast
    ) {
        let increasedContrast = colorSchemeContrast == .increased

        switch renderingMode {
        case .fullColor:
            primary = entry.resolvedTextColor
            secondary = increasedContrast
                ? entry.resolvedTextColor
                : entry.resolvedSecondaryColor
            divider = entry.resolvedTextColor.opacity(increasedContrast ? 0.72 : 0.48)
            indicator = entry.resolvedAccent
            badgeBackground = entry.resolvedAccent.opacity(increasedContrast ? 0.22 : 0.14)

        case .accented:
            // In accented mode WidgetKit ignores hue, preserves alpha, and uses
            // widgetAccentable() to choose the accent/default color group.
            primary = .primary
            secondary = Color.primary.opacity(increasedContrast ? 0.90 : 0.72)
            divider = Color.primary.opacity(increasedContrast ? 0.72 : 0.48)
            indicator = .primary
            badgeBackground = Color.primary.opacity(increasedContrast ? 0.24 : 0.16)

        case .vibrant:
            let primaryLuminance = isLuminanceReduced ? 0.84 : 1.00
            let secondaryLuminance = isLuminanceReduced
                ? (increasedContrast ? 0.76 : 0.62)
                : (increasedContrast ? 0.86 : 0.70)
            let tertiaryLuminance = isLuminanceReduced
                ? (increasedContrast ? 0.62 : 0.46)
                : (increasedContrast ? 0.72 : 0.54)

            primary = Self.opaqueGray(primaryLuminance)
            secondary = Self.opaqueGray(secondaryLuminance)
            divider = Self.opaqueGray(tertiaryLuminance)
            indicator = Self.opaqueGray(primaryLuminance)
            badgeBackground = Self.opaqueGray(isLuminanceReduced ? 0.08 : 0.14)

        default:
            primary = .primary
            secondary = .secondary
            divider = Color.secondary
            indicator = .primary
            badgeBackground = Color.primary.opacity(0.16)
        }
    }

    private static func opaqueGray(_ luminance: Double) -> Color {
        Color(.sRGB, white: luminance, opacity: 1)
    }
}

struct PrayerAccessoryRectangularView: View {
    let entry: PrayerWidgetEntry
    let segment: PrayerAccessoryScheduleSegment

    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    private var palette: PrayerAccessoryPalette {
        PrayerAccessoryPalette(
            entry: entry,
            renderingMode: renderingMode,
            isLuminanceReduced: isLuminanceReduced,
            colorSchemeContrast: colorSchemeContrast
        )
    }

    private var rows: [(Prayer, Date)] {
        segment.prayers.compactMap { prayer in
            guard let date = entry.dayPrayers.first(where: { $0.0 == prayer })?.1 else {
                return nil
            }
            return (prayer, date)
        }
    }

    var body: some View {
        VStack(spacing: 1) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, item in
                let (prayer, date) = item
                prayerRow(
                    prayer: prayer,
                    date: date,
                    isNext: entry.nextPrayer == prayer
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .environment(
            \.layoutDirection,
            PrayerWidgetLocalization.isRTL(language: entry.language)
                ? .rightToLeft
                : .leftToRight
        )
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func prayerRow(prayer: Prayer, date: Date, isNext: Bool) -> some View {
        let nameWeight: Font.Weight = isNext ? .bold : .medium
        let timeWeight: Font.Weight = isNext ? .bold : .semibold
        let rowColor = isNext ? palette.primary : palette.secondary

        let row = HStack(spacing: 7) {
            ZStack {
                Circle()
                    .stroke(isNext ? palette.indicator : palette.secondary, lineWidth: 1.2)
                    .frame(width: 9, height: 9)
                if isNext {
                    Circle()
                        .fill(palette.indicator)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(width: 11)
            .accessibilityHidden(true)

            Text(displayName(for: prayer))
                .font(.system(size: 12, weight: nameWeight))
                .lineLimit(1)
                .minimumScaleFactor(0.62)

            Spacer(minLength: 5)

            Text(PrayerTimeFormatter.formatDevice(
                date,
                useArabicNumerals: entry.arabicNumerals,
                languageCode: entry.language,
                timeZone: entry.settings.displayTimeZone
            ))
                .font(.system(size: 12, weight: timeWeight, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: 18, alignment: .center)
        .foregroundStyle(rowColor)

        if isNext {
            row.widgetAccentable()
        } else {
            row
        }
    }

    private func displayName(for prayer: Prayer) -> String {
        if prayer == .sunrise {
            return PrayerWidgetLocalization.string("shurooq", language: entry.language)
        }
        return PrayerWidgetLocalization.prayerName(prayer, language: entry.language)
    }
}

struct PrayerAccessoryPathView: View {
    let entry: PrayerWidgetEntry

    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    private var palette: PrayerAccessoryPalette {
        PrayerAccessoryPalette(
            entry: entry,
            renderingMode: renderingMode,
            isLuminanceReduced: isLuminanceReduced,
            colorSchemeContrast: colorSchemeContrast
        )
    }

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            pathStop(entry.currentPrayer, highlighted: false)
                .frame(maxWidth: .infinity)
            pathConnector
            pathStop(
                entry.nextPrayer,
                highlighted: true,
                countdownTarget: entry.nextPrayerDate
            )
                .frame(maxWidth: .infinity)
            pathConnector
            pathStop(entry.followingPrayer, highlighted: false)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .environment(
            \.layoutDirection,
            PrayerWidgetLocalization.isRTL(language: entry.language)
                ? .rightToLeft
                : .leftToRight
        )
        .accessibilityElement(children: .combine)
    }

    private var pathConnector: some View {
        Rectangle()
            .fill(palette.divider)
            .frame(width: 10, height: 1)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func pathStop(
        _ prayer: Prayer?,
        highlighted: Bool,
        countdownTarget: Date? = nil
    ) -> some View {
        if let prayer {
            let stop = VStack(spacing: 2) {
                Circle()
                    .fill(highlighted ? palette.indicator : palette.secondary)
                    .frame(
                        width: highlighted ? 8 : 6,
                        height: highlighted ? 8 : 6
                    )
                Text(PrayerWidgetLocalization.prayerName(
                    prayer,
                    language: entry.language
                ))
                    .font(.system(size: 10, weight: highlighted ? .bold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)

                if let target = countdownTarget, target > entry.date {
                    // Text(timerInterval:) reserves its widest possible value
                    // in an installed Lock Screen widget. Give it a bounded
                    // slot; fixedSize() here can collapse the surrounding
                    // three-column path even though the static gallery sample
                    // looks correct.
                    AdaptiveCountdownText(
                        entry: entry,
                        target: target,
                        font: .system(size: 11, weight: .bold, design: .rounded),
                        compact: true
                    )
                    .frame(width: 34, alignment: .center)
                    .environment(
                        \.locale,
                        prayerCountdownTimerLocale(
                            useArabicNumerals: entry.arabicNumerals
                        )
                    )
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(palette.badgeBackground)
                    )
                }
            }
            .foregroundStyle(highlighted ? palette.primary : palette.secondary)

            if highlighted {
                stop.widgetAccentable()
            } else {
                stop
            }
        }
    }
}

struct PrayerAccessoryAlmanacView: View {
    let entry: PrayerWidgetEntry

    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    private var palette: PrayerAccessoryPalette {
        PrayerAccessoryPalette(
            entry: entry,
            renderingMode: renderingMode,
            isLuminanceReduced: isLuminanceReduced,
            colorSchemeContrast: colorSchemeContrast
        )
    }

    private var activeDate: Date {
        entry.nextPrayerDate ?? entry.date
    }

    var body: some View {
        HStack(spacing: 10) {
            VStack(spacing: -3) {
                Text(weekday)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(palette.secondary)
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text(dayNumber)
                    .font(.system(size: 30, weight: .light, design: .serif))
                    .foregroundStyle(palette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(width: 43)

            Rectangle()
                .fill(palette.divider)
                .frame(width: 1)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(PrayerWidgetLocalization.string(
                    "next_prayer",
                    language: entry.language
                ))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(palette.secondary)
                    .tracking(1.1)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)

                if let next = entry.nextPrayer {
                    Text(PrayerWidgetLocalization.prayerName(
                        next,
                        language: entry.language
                    ))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(palette.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                }

                HStack(spacing: 4) {
                    if let target = entry.nextPrayerDate {
                        Text(PrayerTimeFormatter.format12(
                            target,
                            useArabicNumerals: entry.arabicNumerals,
                            timeZone: entry.settings.displayTimeZone
                        ))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .monospacedDigit()

                        Text("·")

                        if target > entry.date {
                            AdaptiveCountdownText(
                                entry: entry,
                                target: target,
                                font: .system(size: 12, weight: .bold, design: .rounded),
                                compact: true
                            )
                                .environment(
                                    \.locale,
                                    prayerCountdownTimerLocale(
                                        useArabicNumerals: entry.arabicNumerals
                                    )
                                )
                        }
                    }
                }
                .lineLimit(1)
                .foregroundStyle(palette.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .widgetAccentable()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .environment(
            \.layoutDirection,
            PrayerWidgetLocalization.isRTL(language: entry.language)
                ? .rightToLeft
                : .leftToRight
        )
        .accessibilityElement(children: .combine)
    }

    private var weekday: String {
        let formatter = DateFormatter()
        formatter.timeZone = entry.settings.displayTimeZone
        formatter.locale = Locale(identifier: entry.language)
        formatter.dateFormat = "EEE"
        return formatter.string(from: activeDate)
            .uppercased(with: formatter.locale)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.timeZone = entry.settings.displayTimeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d"
        return PrayerTimeFormatter.applyNumerals(
            formatter.string(from: activeDate),
            useArabicNumerals: entry.arabicNumerals
        )
    }
}

struct PrayerAccessoryInlineView: View {
    let entry: PrayerWidgetEntry

    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    var body: some View {
        let palette = PrayerAccessoryPalette(
            entry: entry,
            renderingMode: renderingMode,
            isLuminanceReduced: isLuminanceReduced,
            colorSchemeContrast: colorSchemeContrast
        )

        Group {
            if let next = entry.nextPrayer, let target = entry.nextPrayerDate {
                let name = PrayerWidgetLocalization.prayerName(next, language: entry.language)
                if target > entry.date {
                    Text("\(name) • ") + Text(timerInterval: entry.date...target, countsDown: true)
                } else {
                    Text(name)
                }
            } else {
                Text(PrayerWidgetLocalization.string("empty_message", language: entry.language))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(palette.primary)
    }
}
