import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Huda Widget" }
    static var description: IntentDescription { "Display beautiful Quranic verses on your home screen" }
}
