import WidgetKit
import SwiftUI
import Intents

// Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct HudaWidgetProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> HudaWidgetEntry {
        let colors = getThemeColors()
        return HudaWidgetEntry(date: Date(), quote: "وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ", configuration: ConfigurationIntent(), themeColors: (colors.primary, colors.accent), isDark: colors.isDark)
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (HudaWidgetEntry) -> ()) {
        let colors = getThemeColors()
        let entry = HudaWidgetEntry(date: Date(), quote: getStoredQuote(), configuration: configuration, themeColors: (colors.primary, colors.accent), isDark: colors.isDark)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [HudaWidgetEntry] = []

        // Generate a timeline consisting of one entry, updated every hour
        let currentDate = Date()
        let quote = getStoredQuote()
        let colors = getThemeColors()
        let entry = HudaWidgetEntry(date: currentDate, quote: quote, configuration: configuration, themeColors: (colors.primary, colors.accent), isDark: colors.isDark)
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!))
        completion(timeline)
    }
    
    private func getStoredQuote() -> String {
        let userDefaults = UserDefaults(suiteName: "group.com.aw.huda.widget")
        return userDefaults?.string(forKey: "quote") ?? "وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ"
    }
    
    private func getThemeColors() -> (primary: Color, accent: Color, isDark: Bool) {
        let userDefaults = UserDefaults(suiteName: "group.com.aw.huda.widget")
        let primaryHex = userDefaults?.string(forKey: "themeColorPrimary") ?? "#674B5D"
        let accentHex = userDefaults?.string(forKey: "themeColorAccent") ?? "#8B5CF6"
        let themeMode = userDefaults?.string(forKey: "themeMode") ?? "light"
        
        return (
            primary: Color(hex: primaryHex),
            accent: Color(hex: accentHex),
            isDark: themeMode == "dark"
        )
    }
}

struct HudaWidgetEntry: TimelineEntry {
    let date: Date
    let quote: String
    let configuration: ConfigurationIntent
    let themeColors: (primary: Color, accent: Color)
    let isDark: Bool
    
    init(date: Date, quote: String, configuration: ConfigurationIntent, themeColors: (primary: Color, accent: Color) = (Color(hex: "#674B5D"), Color(hex: "#8B5CF6")), isDark: Bool = false) {
        self.date = date
        self.quote = quote
        self.configuration = configuration
        self.themeColors = themeColors
        self.isDark = isDark
    }
}

struct HudaWidgetEntryView : View {
    var entry: HudaWidgetProvider.Entry

    var body: some View {
        ZStack {
            // Background with theme-aware gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    entry.isDark ? Color(.systemGray6) : Color(.systemBackground),
                    entry.isDark ? Color(.systemGray5).opacity(0.3) : Color(.systemGray6).opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 0) {
                // Header with decorative elements
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(entry.themeColors.accent)
                        .frame(width: 30, height: 3)
                        .cornerRadius(1.5)
                    
                    Text("🕌")
                        .font(.system(size: 14))
                    Text("هُدى")
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(entry.themeColors.primary)
                        .tracking(0.5)
                    
                    Rectangle()
                        .fill(entry.themeColors.accent)
                        .frame(width: 30, height: 3)
                        .cornerRadius(1.5)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Main content area
                VStack(spacing: 8) {
                    Spacer()
                    
                    Text(entry.quote)
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundColor(entry.isDark ? .white : .primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .minimumScaleFactor(0.7)
                        .lineSpacing(3)
                        .environment(\.layoutDirection, .rightToLeft)
                        .padding(.horizontal, 8)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                
                // Footer with decorative line and update time
                VStack(spacing: 6) {
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [entry.themeColors.accent.opacity(0.6), entry.themeColors.accent.opacity(0.3)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: 40, height: 2)
                        .cornerRadius(1)
                    
                    Text("آخر تحديث: \(formatTime(entry.date))")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(entry.isDark ? Color(.systemGray2) : .secondary)
                        .opacity(0.8)
                }
                .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(entry.isDark ? Color(.systemGray6) : Color(.systemBackground))
                .shadow(color: Color.black.opacity(entry.isDark ? 0.15 : 0.08), radius: 3, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5).opacity(entry.isDark ? 0.8 : 0.6), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: date)
    }
}

struct HudaWidget: Widget {
    let kind: String = "HudaWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: HudaWidgetProvider()) { entry in
            HudaWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("🕌 هُدى")
        .description("Quran Verses Widget - Display inspiring verses that update automatically")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HudaWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HudaWidgetEntryView(entry: HudaWidgetEntry(date: Date(), quote: "إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا", configuration: ConfigurationIntent(), themeColors: (Color(hex: "#674B5D"), Color(hex: "#8B5CF6")), isDark: false))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small Widget - Light")
            
            HudaWidgetEntryView(entry: HudaWidgetEntry(date: Date(), quote: "وَٱللَّهُ غَفُورٌ رَّحِيمٌ", configuration: ConfigurationIntent(), themeColors: (Color(hex: "#22C55E"), Color(hex: "#10B981")), isDark: false))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium Widget - Light")
                
            HudaWidgetEntryView(entry: HudaWidgetEntry(date: Date(), quote: "إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا", configuration: ConfigurationIntent(), themeColors: (Color(hex: "#674B5D"), Color(hex: "#8B5CF6")), isDark: true))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small Widget - Dark")
        }
    }
}
