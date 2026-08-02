import WidgetKit
import SwiftUI

struct HudaWidgetEntry: TimelineEntry {
    let date: Date
    let quote: String
    let themeColors: ThemeColors
}

struct HudaWidgetProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> HudaWidgetEntry {
        HudaWidgetEntry(
            date: Date(),
            quote: WidgetDataLoader.defaultVerses[0],
            themeColors: WidgetThemeColors.getThemeColors(themeName: "teal", isDarkMode: false)
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HudaWidgetEntry) -> Void) {
        let entry = HudaWidgetEntry(
            date: Date(),
            quote: WidgetDataLoader.getCurrentQuote(),
            themeColors: WidgetDataLoader.getThemeColors()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<HudaWidgetEntry>) -> Void) {
        var entries: [HudaWidgetEntry] = []
        let currentDate = Date()

        for minuteOffset in stride(from: 0, to: 60 * 4, by: 15) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = HudaWidgetEntry(
                date: entryDate,
                quote: WidgetDataLoader.getCurrentQuote(),
                themeColors: WidgetDataLoader.getThemeColors()
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct HudaWidgetEntryView: View {
    var entry: HudaWidgetEntry
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    
    var body: some View {
        VStack(spacing: verticalSpacing) {
            headerSection

            quoteCard

            bottomDecoration
        }
        .padding(contentPadding)
    }

    private var adaptiveAccentColor: Color {
        switch widgetRenderingMode {
        case .vibrant, .accented:
            return .primary
        default:
            return entry.themeColors.accent
        }
    }

    private var adaptiveTextColor: Color {
        switch widgetRenderingMode {
        case .vibrant, .accented:
            return .primary
        default:
            return entry.themeColors.quoteTextColor
        }
    }

    private var adaptiveCardBackground: Color {
        switch widgetRenderingMode {
        case .vibrant, .accented:
            return .white.opacity(0.2)
        default:
            return entry.themeColors.quoteCardBackground
        }
    }

    private var adaptiveBadgeBackground: Color {
        switch widgetRenderingMode {
        case .vibrant, .accented:
            return .white.opacity(0.15)
        default:
            return entry.themeColors.accent.opacity(0.15)
        }
    }

    private var headerSection: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(adaptiveAccentColor)
                .frame(width: lineWidth, height: 2)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(adaptiveBadgeBackground)
                    .frame(width: iconBadgeSize, height: iconBadgeSize * 0.6)
                
                Image("HudaLogo")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize * 1.5, height: iconSize)
                    .foregroundColor(adaptiveAccentColor)
            }

            Rectangle()
                .fill(adaptiveAccentColor)
                .frame(width: lineWidth, height: 2)
        }
    }

    private var quoteCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(adaptiveCardBackground)
            
            Text(entry.quote)
                .font(.custom("Amiri", size: quoteFontSize))
                .foregroundColor(adaptiveTextColor)
                .multilineTextAlignment(.center)
                .lineLimit(maxLines)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(height: quoteCardHeight)
    }

    private var bottomDecoration: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(adaptiveAccentColor.opacity(0.5))
            .frame(width: 50, height: 4)
    }

    private var verticalSpacing: CGFloat {
        switch widgetFamily {
        case .systemSmall: return 6
        case .systemMedium: return 8
        case .systemLarge: return 10
        default: return 8
        }
    }
    
    private var contentPadding: CGFloat {
        switch widgetFamily {
        case .systemSmall: return 10
        case .systemMedium: return 12
        case .systemLarge: return 14
        default: return 12
        }
    }
    
    private var lineWidth: CGFloat {
        switch widgetFamily {
        case .systemSmall: return 30
        case .systemMedium: return 50
        case .systemLarge: return 60
        default: return 50
        }
    }
    
    private var iconBadgeSize: CGFloat {
        switch widgetFamily {
        case .systemSmall: return 36
        case .systemMedium: return 44
        case .systemLarge: return 52
        default: return 44
        }
    }
    
    private var iconSize: CGFloat {
        switch widgetFamily {
        case .systemSmall: return 14
        case .systemMedium: return 18
        case .systemLarge: return 22
        default: return 18
        }
    }
    
    private var quoteFontSize: CGFloat {
        switch widgetFamily {
        case .systemSmall: return 16
        case .systemMedium: return 20
        case .systemLarge: return 24
        default: return 20
        }
    }
    
    private var quoteCardHeight: CGFloat {
        switch widgetFamily {
        case .systemSmall: return 80
        case .systemMedium: return 100
        case .systemLarge: return 200
        default: return 100
        }
    }
    
    private var maxLines: Int {
        switch widgetFamily {
        case .systemSmall: return 3
        case .systemMedium: return 4
        case .systemLarge: return 8
        default: return 4
        }
    }
}

struct HudaWidget: Widget {
    let kind: String = "HudaWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HudaWidgetProvider()) { entry in
            HudaWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [entry.themeColors.gradientStart, entry.themeColors.gradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Huda")
        .description("Beautiful Quranic verses on your home screen")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    HudaWidget()
} timeline: {
    HudaWidgetEntry(
        date: .now,
        quote: "إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا",
        themeColors: WidgetThemeColors.getThemeColors(themeName: "purple", isDarkMode: false)
    )
    HudaWidgetEntry(
        date: .now,
        quote: "وَٱللَّهُ غَفُورٌ رَّحِيمٌ",
        themeColors: WidgetThemeColors.getThemeColors(themeName: "green", isDarkMode: true)
    )
}
