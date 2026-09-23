import WidgetKit
import SwiftUI
import UIKit

struct HudaWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: QuranWidgetSnapshot
}

struct HudaWidgetProvider: TimelineProvider {
    private static let futureEntryCount = 8

    func placeholder(in context: Context) -> HudaWidgetEntry {
        HudaWidgetEntry(
            date: Date(),
            snapshot: WidgetDataLoader.snapshot(size: context.family.quranWidgetSize)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HudaWidgetEntry) -> Void) {
        completion(
            HudaWidgetEntry(
                date: Date(),
                snapshot: WidgetDataLoader.snapshot(size: context.family.quranWidgetSize)
            )
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HudaWidgetEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let nextHour =
            calendar.dateInterval(of: .hour, for: now)?.end
            ?? now.addingTimeInterval(3600)
        let size = context.family.quranWidgetSize
        var entries = [
            HudaWidgetEntry(
                date: now,
                snapshot: WidgetDataLoader.snapshot(at: now, size: size)
            )
        ]
        for hourOffset in 0..<Self.futureEntryCount {
            guard let date = calendar.date(byAdding: .hour, value: hourOffset, to: nextHour) else {
                continue
            }
            entries.append(
                HudaWidgetEntry(
                    date: date,
                    snapshot: WidgetDataLoader.snapshot(at: date, size: size)
                )
            )
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

private extension WidgetFamily {
    var quranWidgetSize: QuranWidgetSize {
        switch self {
        case .systemLarge:
            return .large
        case .systemMedium:
            return .medium
        default:
            return .small
        }
    }
}

struct HudaWidgetEntryView: View {
    let entry: HudaWidgetEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        GeometryReader { geometry in
            let layout = QuranNoorLayout(size: geometry.size, family: family)
            let textLayout = makeTextLayout(layout: layout)

            VStack(spacing: 0) {
                QuranNoorHeader(
                    reference: entry.snapshot.displayReference,
                    appLanguage: entry.snapshot.appLanguage,
                    micro: layout.isMicro,
                    compact: layout.isCompact,
                    expanded: layout.isExpanded,
                    palette: entry.snapshot.palette,
                    fullColor: isFullColor
                )

                Spacer().frame(height: layout.headerGap)

                VStack(spacing: 0) {
                    Text(entry.snapshot.verse.arabic)
                        .font(.custom(ayahFontName, size: textLayout.ayahFontSize))
                        .foregroundStyle(ayahColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(layout.arabicLineSpacing)
                        .lineLimit(textLayout.ayahLineLimit)
                        .truncationMode(.tail)
                        .environment(\.layoutDirection, .rightToLeft)
                        .frame(maxWidth: .infinity)
                        .frame(height: textLayout.ayahHeight)
                        .clipped()

                    if textLayout.showsTranslation,
                        let translation = entry.snapshot.translation,
                        !translation.isEmpty
                    {
                        QuranNoorDivider(
                            micro: layout.isMicro,
                            compact: layout.isCompact,
                            palette: entry.snapshot.palette,
                            fullColor: isFullColor
                        )

                        Text(translation)
                            .font(
                                .system(
                                    size: textLayout.translationFontSize,
                                    weight: entry.snapshot.translationBold ? .bold : .regular
                                )
                            )
                            .foregroundStyle(translationColor)
                            .multilineTextAlignment(.center)
                            .lineSpacing(layout.translationLineSpacing)
                            .lineLimit(textLayout.translationLineLimit)
                            .truncationMode(.tail)
                            .environment(
                                \.layoutDirection,
                                entry.snapshot.translationLanguage == "ur"
                                    ? .rightToLeft
                                    : .leftToRight
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: textLayout.translationHeight)
                            .clipped()
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .padding(.horizontal, layout.horizontalPadding)
            .padding(.vertical, layout.verticalPadding)
        }
        .overlay {
            ContainerRelativeShape()
                .stroke(borderGradient, lineWidth: 1)
        }
        .overlay {
            ContainerRelativeShape()
                .inset(by: 1.5)
                .stroke(ayahColor.opacity(0.09), lineWidth: 0.75)
        }
        .widgetURL(URL(string: "huda://quran"))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var isFullColor: Bool { renderingMode == .fullColor }

    private var ayahFontName: String {
        entry.snapshot.ayahBold ? "Amiri-Bold" : "Amiri-Regular"
    }

    private var ayahColor: Color {
        isFullColor ? entry.snapshot.palette.ayah : .primary
    }

    private var translationColor: Color {
        isFullColor ? entry.snapshot.palette.translation.opacity(0.90) : .secondary
    }

    private var borderGradient: LinearGradient {
        let palette = entry.snapshot.palette
        return LinearGradient(
            stops: [
                .init(
                    color: isFullColor ? palette.accent.opacity(0.62) : .primary.opacity(0.55),
                    location: 0.00
                ),
                .init(
                    color: isFullColor ? palette.ayah.opacity(0.16) : .primary.opacity(0.12),
                    location: 0.36
                ),
                .init(
                    color: isFullColor ? palette.ornament.opacity(0.34) : .primary.opacity(0.30),
                    location: 0.72
                ),
                .init(
                    color: isFullColor ? palette.accent.opacity(0.18) : .primary.opacity(0.16),
                    location: 1.00
                ),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func makeTextLayout(layout: QuranNoorLayout) -> QuranNoorTextLayout {
        let hasTranslation = !(entry.snapshot.translation?.isEmpty ?? true)
        let availableWidth = max(1, layout.size.width - layout.horizontalPadding * 2)
        let availableHeight = max(
            1,
            layout.size.height
                - layout.verticalPadding * 2
                - layout.headerDiameter
                - layout.headerGap
        )
        let ayahBaseSize: CGFloat = layout.isExpanded ? 27 : layout.isCompact ? 17 : 20
        let translationBaseSize: CGFloat = layout.isExpanded ? 13 : layout.isCompact ? 9 : 10.5
        var ayahSize = ayahBaseSize * (entry.snapshot.ayahAutoFit ? 1 : entry.snapshot.ayahTextScale)
        var translationSize =
            translationBaseSize * (entry.snapshot.translationAutoFit ? 1 : entry.snapshot.translationTextScale)
        let translationFloor: CGFloat = layout.isExpanded ? 8 : 9
        let showsTranslation = hasTranslation
        let dividerHeight = layout.dividerHeight

        func ayahMetrics() -> QuranNoorTextMetrics {
            textMetrics(
                entry.snapshot.verse.arabic,
                font: UIFont(name: ayahFontName, size: ayahSize)
                    ?? UIFont.systemFont(ofSize: ayahSize),
                width: availableWidth,
                lineSpacing: layout.arabicLineSpacing
            )
        }

        func translationMetrics() -> QuranNoorTextMetrics? {
            guard showsTranslation, let translation = entry.snapshot.translation else { return nil }
            return textMetrics(
                translation,
                font: UIFont.systemFont(
                    ofSize: translationSize,
                    weight: entry.snapshot.translationBold ? .bold : .regular
                ),
                width: availableWidth,
                lineSpacing: layout.translationLineSpacing
            )
        }

        func totalHeight() -> CGFloat {
            let ayah = ayahMetrics().fullHeight
            guard let translation = translationMetrics() else { return ayah }
            return ayah + dividerHeight + translation.fullHeight
        }

        for _ in 0..<120 {
            if totalHeight() <= availableHeight { break }
            if entry.snapshot.translationAutoFit,
                showsTranslation,
                translationSize > translationFloor
            {
                translationSize = max(translationFloor, translationSize - 0.5)
            } else if entry.snapshot.ayahAutoFit, ayahSize > 14 {
                ayahSize = max(14, ayahSize - 0.5)
            } else {
                break
            }
        }

        var ayahLines = ayahMetrics().lineCount
        var translationLines = translationMetrics()?.lineCount ?? 0
        func limitedTotalHeight() -> CGFloat {
            let ayah = ayahMetrics().height(for: ayahLines)
            guard let translation = translationMetrics() else { return ayah }
            return ayah + dividerHeight + translation.height(for: translationLines)
        }

        while showsTranslation && limitedTotalHeight() > availableHeight && translationLines > 1 {
            translationLines -= 1
        }
        while limitedTotalHeight() > availableHeight && ayahLines > 1 {
            ayahLines -= 1
        }

        let finalAyahMetrics = ayahMetrics()
        let finalTranslationMetrics = translationMetrics()
        var ayahHeight = finalAyahMetrics.height(for: ayahLines)
        var translationHeight = finalTranslationMetrics?.height(for: translationLines) ?? 0
        let requiredHeight =
            ayahHeight
            + (showsTranslation ? dividerHeight + translationHeight : 0)
        if requiredHeight > availableHeight {
            if showsTranslation {
                let textHeight = max(2, availableHeight - dividerHeight)
                ayahHeight = max(1, textHeight * 0.62)
                translationHeight = max(1, textHeight - ayahHeight)
            } else {
                ayahHeight = availableHeight
            }
        }

        return QuranNoorTextLayout(
            ayahFontSize: ayahSize,
            translationFontSize: translationSize,
            ayahHeight: ayahHeight,
            translationHeight: translationHeight,
            ayahLineLimit: max(1, ayahLines),
            translationLineLimit: max(1, translationLines),
            showsTranslation: showsTranslation
        )
    }

    private func textMetrics(
        _ text: String,
        font: UIFont,
        width: CGFloat,
        lineSpacing: CGFloat
    ) -> QuranNoorTextMetrics {
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        let lineCount = max(1, Int(ceil(bounds.height / font.lineHeight)))
        return QuranNoorTextMetrics(
            lineCount: lineCount,
            lineHeight: ceil(font.lineHeight),
            lineSpacing: lineSpacing
        )
    }

    private var accessibilityLabel: String {
        [
            entry.snapshot.verse.arabic,
            entry.snapshot.translation,
            entry.snapshot.displayReference,
        ]
        .compactMap { $0 }
        .joined(separator: ". ")
    }
}

private struct QuranNoorLayout {
    let size: CGSize
    let isMicro: Bool
    let isCompact: Bool
    let isExpanded: Bool
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let headerDiameter: CGFloat
    let headerGap: CGFloat
    let arabicLineSpacing: CGFloat
    let translationLineSpacing: CGFloat
    let dividerHeight: CGFloat

    init(size: CGSize, family: WidgetFamily) {
        self.size = size
        isMicro = size.width < 145 || size.height < 120
        isExpanded = family == .systemLarge || size.height >= 235
        isCompact = family == .systemSmall || size.width < 330 || size.height < 172

        if isExpanded {
            horizontalPadding = 24
            verticalPadding = 18
            headerDiameter = 34
            headerGap = 13
            arabicLineSpacing = 7
            translationLineSpacing = 2
            dividerHeight = 11
        } else if isMicro {
            horizontalPadding = 10
            verticalPadding = 5
            headerDiameter = 23
            headerGap = 1
            arabicLineSpacing = 2
            translationLineSpacing = 1
            dividerHeight = 6
        } else if isCompact {
            horizontalPadding = 14
            verticalPadding = 7
            headerDiameter = 25
            headerGap = 2
            arabicLineSpacing = 2.5
            translationLineSpacing = 1
            dividerHeight = 7
        } else {
            horizontalPadding = 18
            verticalPadding = 10
            headerDiameter = 29
            headerGap = 4
            arabicLineSpacing = 4
            translationLineSpacing = 1.5
            dividerHeight = 9
        }
    }
}

private struct QuranNoorTextLayout {
    let ayahFontSize: CGFloat
    let translationFontSize: CGFloat
    let ayahHeight: CGFloat
    let translationHeight: CGFloat
    let ayahLineLimit: Int
    let translationLineLimit: Int
    let showsTranslation: Bool
}

private struct QuranNoorTextMetrics {
    let lineCount: Int
    let lineHeight: CGFloat
    let lineSpacing: CGFloat

    var fullHeight: CGFloat { height(for: lineCount) }

    func height(for requestedLines: Int) -> CGFloat {
        let lines = max(1, min(requestedLines, lineCount))
        return CGFloat(lines) * lineHeight + CGFloat(max(0, lines - 1)) * lineSpacing
    }
}

private struct QuranNoorHeader: View {
    let reference: String
    let appLanguage: String
    let micro: Bool
    let compact: Bool
    let expanded: Bool
    let palette: QuranWidgetPalette
    let fullColor: Bool

    var body: some View {
        HStack(spacing: 0) {
            QuranNoorMedallion(
                size: expanded ? 34 : micro ? 23 : compact ? 25 : 29,
                palette: palette,
                fullColor: fullColor
            )
            .offset(y: 2)

            Spacer(minLength: 8)

            HStack(spacing: 5) {
                Circle()
                    .fill(fullColor ? palette.ornament : .primary)
                    .frame(width: 3.5, height: 3.5)

                Text(reference)
                    .font(.system(size: compact ? 8 : expanded ? 10 : 8.8, weight: .medium))
                    .tracking(0.15)
                    .foregroundStyle(fullColor ? palette.ayah.opacity(0.92) : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
            }
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 3 : 4)
            .background(
                (fullColor ? palette.ayah : Color.primary)
                    .opacity(fullColor && palette.isLight ? 0.055 : 0.075),
                in: Capsule()
            )
            .overlay {
                Capsule().stroke(
                    (fullColor ? palette.ayah : Color.primary).opacity(0.14),
                    lineWidth: 0.75
                )
            }
            .frame(maxWidth: compact ? 155 : expanded ? 235 : 205, alignment: .trailing)
        }
        .environment(\.layoutDirection, .leftToRight)
        .offset(y: compact ? -2 : -4)
    }

    private var isRTL: Bool { appLanguage == "ar" || appLanguage == "ur" }
}

private struct QuranNoorMedallion: View {
    let size: CGFloat
    let palette: QuranWidgetPalette
    let fullColor: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: fullColor
                            ? [palette.accent.opacity(0.22), palette.ayah.opacity(0.06)]
                            : [.primary.opacity(0.22), .primary.opacity(0.06)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )

            Circle()
                .stroke(
                    (fullColor ? palette.accent : Color.primary).opacity(0.38),
                    lineWidth: 0.75
                )

            Image("HudaLogo")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle((fullColor ? palette.ayah : Color.primary).opacity(0.96))
                .padding(size * 0.15)
        }
        .frame(width: size, height: size)
    }
}

private struct QuranNoorDivider: View {
    let micro: Bool
    let compact: Bool
    let palette: QuranWidgetPalette
    let fullColor: Bool

    var body: some View {
        HStack(spacing: 5) {
            LinearGradient(
                colors: [
                    .clear,
                    (fullColor ? palette.accent : Color.primary).opacity(0.58),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: compact ? 26 : 34, height: 0.75)

            Circle()
                .fill((fullColor ? palette.ornament : Color.primary).opacity(0.92))
                .frame(width: 3, height: 3)

            LinearGradient(
                colors: [
                    (fullColor ? palette.accent : Color.primary).opacity(0.58),
                    .clear,
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: compact ? 26 : 34, height: 0.75)
        }
        .padding(.vertical, micro ? 1.5 : compact ? 2 : 3)
    }
}

private struct QuranNoorBackground: View {
    let palette: QuranWidgetPalette

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: fullColor
                        ? [palette.surface, palette.background, palette.background]
                        : [.primary.opacity(0.28), .primary.opacity(0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        (fullColor ? palette.accent : Color.primary)
                            .opacity(palette.isLight ? 0.16 : 0.27),
                        .clear,
                    ],
                    center: UnitPoint(x: 0.50, y: 0.18),
                    startRadius: 0,
                    endRadius: geometry.size.width * 0.62
                )

                RadialGradient(
                    colors: [
                        (fullColor ? palette.ornament : Color.primary).opacity(0.14),
                        .clear,
                    ],
                    center: UnitPoint(x: 0.88, y: -0.02),
                    startRadius: 0,
                    endRadius: geometry.size.width * 0.37
                )

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.48),
                        .init(
                            color: .black.opacity(fullColor && !palette.isLight ? 0.22 : 0.08),
                            location: 1.00
                        ),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                QuranNoorSacredGeometry(
                    palette: palette,
                    fullColor: fullColor
                )
            }
        }
    }

    private var fullColor: Bool { renderingMode == .fullColor }
}

private struct QuranNoorSacredGeometry: View {
    let palette: QuranWidgetPalette
    let fullColor: Bool

    var body: some View {
        Canvas { context, size in
            var arch = Path()
            arch.move(to: CGPoint(x: size.width * 0.18, y: size.height * 0.92))
            arch.addCurve(
                to: CGPoint(x: size.width * 0.50, y: size.height * 0.08),
                control1: CGPoint(x: size.width * 0.18, y: size.height * 0.50),
                control2: CGPoint(x: size.width * 0.35, y: size.height * 0.22)
            )
            arch.addCurve(
                to: CGPoint(x: size.width * 0.82, y: size.height * 0.92),
                control1: CGPoint(x: size.width * 0.65, y: size.height * 0.22),
                control2: CGPoint(x: size.width * 0.82, y: size.height * 0.50)
            )
            context.stroke(
                arch,
                with: .color(
                    (fullColor ? palette.accent : Color.primary)
                        .opacity(palette.isLight ? 0.10 : 0.075)
                ),
                style: StrokeStyle(lineWidth: 1, lineCap: .round)
            )

            context.stroke(
                eightPointStar(
                    center: CGPoint(x: size.width * 0.96, y: size.height * 0.06),
                    outerRadius: min(size.width, size.height) * 0.34
                ),
                with: .color(
                    (fullColor ? palette.ornament : Color.primary)
                        .opacity(palette.isLight ? 0.12 : 0.075)
                ),
                lineWidth: 1
            )
            context.stroke(
                eightPointStar(
                    center: CGPoint(x: size.width * 0.02, y: size.height * 0.98),
                    outerRadius: min(size.width, size.height) * 0.23
                ),
                with: .color(
                    (fullColor ? palette.accent : Color.primary)
                        .opacity(palette.isLight ? 0.09 : 0.055)
                ),
                lineWidth: 1
            )
        }
    }

    private func eightPointStar(center: CGPoint, outerRadius: CGFloat) -> Path {
        var path = Path()
        let innerRadius = outerRadius * 0.46
        for index in 0..<16 {
            let angle = -Double.pi / 2 + Double(index) * Double.pi / 8
            let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
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

struct HudaWidget: Widget {
    let kind = "HudaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HudaWidgetProvider()) { entry in
            HudaWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    QuranNoorBackground(palette: entry.snapshot.palette)
                }
        }
        .configurationDisplayName("Quran Verse")
        .description("An ayah with an optional translation, refreshed every hour.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}
