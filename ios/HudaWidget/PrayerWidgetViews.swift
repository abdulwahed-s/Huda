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

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "location.slash")
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(entry.resolvedAccent)

            Text(PrayerWidgetLocalization.string(
                "empty_message",
                language: entry.language
            ))
            .font(.system(size: messageFontSize, weight: .semibold))
            .multilineTextAlignment(.center)
            .foregroundColor(entry.resolvedTextColor)
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

    private func compactCountdownText(fontSize: CGFloat) -> Text {
        guard let target = entry.nextPrayerDate, target > entry.date else {
            return Text("")
        }
        let text = PrayerWidgetLocalization.compactCountdown(
            from: entry.date, to: target,
            useArabicNumerals: entry.arabicNumerals,
            languageCode: entry.language
        )
        return Text(text)
            .font(.system(size: fontSize * entry.contentScale, weight: .medium))
            .foregroundColor(entry.resolvedSecondaryColor)
            .monospacedDigit()
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

private extension PrayerWidgetLocalization {
    static func compactCountdown(
        from start: Date,
        to end: Date,
        useArabicNumerals: Bool,
        languageCode: String
    ) -> String {
        return PrayerTimeFormatter.formatCompactRelative(
            from: start,
            to: end,
            useArabicNumerals: useArabicNumerals,
            languageCode: languageCode
        )
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
                Text(timerInterval: entry.date...target, countsDown: true)
                    .font(serif(18, weight: .bold))
                    .foregroundColor(primaryText)
                    .monospacedDigit()
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
                Text(timerInterval: entry.date...target, countsDown: true)
                    .font(serif(13, weight: .bold))
                    .foregroundColor(highlight)
                    .monospacedDigit()
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
                Text(timerInterval: entry.date...target, countsDown: true)
                    .font(serif(22, weight: .regular))
                    .foregroundColor(primaryText)
                    .monospacedDigit()
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
        if target.timeIntervalSince(entry.date) > Self.oneHour {
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

    var body: some View {
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
        .environment(\.layoutDirection,
                     PrayerWidgetLocalization.isRTL(language: entry.language) ? .rightToLeft : .leftToRight)
    }
}

struct PrayerAccessoryRectangularView: View {
    let entry: PrayerWidgetEntry

    private var prayers: [(Prayer, Date)] {
        entry.dayPrayers.filter { $0.0 != .sunrise }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            countdownLine
            prayerStrip
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .environment(\.layoutDirection,
                     PrayerWidgetLocalization.isRTL(language: entry.language) ? .rightToLeft : .leftToRight)
    }

    @ViewBuilder
    private var countdownLine: some View {
        if let next = entry.nextPrayer,
           let target = entry.nextPrayerDate,
           target > entry.date {
            HStack(spacing: 3) {
                Text(PrayerWidgetLocalization.prayerName(next, language: entry.language))
                    .font(.system(size: 12, weight: .bold))
                Text(PrayerWidgetLocalization.string("in_word", language: entry.language))
                    .font(.system(size: 12, weight: .regular))
                AdaptiveCountdownText(
                    entry: entry,
                    target: target,
                    font: .system(size: 12, weight: .bold, design: .rounded)
                )
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .widgetAccentable()
            .frame(maxWidth: .infinity, alignment: .center)
        } else {
            Text(PrayerWidgetLocalization.string("empty_message",
                                                 language: entry.language))
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var prayerStrip: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            ForEach(Array(prayers.enumerated()), id: \.offset) { _, item in
                let (prayer, date) = item
                let isNext = entry.nextPrayer == prayer
                cell(prayer: prayer, date: date, isNext: isNext)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func cell(prayer: Prayer, date: Date, isNext: Bool) -> some View {
        let nameWeight: Font.Weight = isNext ? .heavy : .medium
        let timeWeight: Font.Weight = isNext ? .heavy : .semibold
        let content = VStack(spacing: 0) {
            Text(PrayerWidgetLocalization.prayerName(prayer, language: entry.language))
                .font(.system(size: 9, weight: nameWeight))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(PrayerTimeFormatter.format(
                date,
                useArabicNumerals: entry.arabicNumerals,
                timeZone: entry.settings.displayTimeZone
            ))
                .font(.system(size: 10, weight: timeWeight, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }

        if isNext {
            content.widgetAccentable()
        } else {
            content
        }
    }
}

struct PrayerAccessoryInlineView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
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
}
