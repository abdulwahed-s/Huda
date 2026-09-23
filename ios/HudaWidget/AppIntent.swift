import AppIntents
import WidgetKit

@available(iOSApplicationExtension 17.0, *)
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource {
        "Huda Widget"
    }

    static var description: IntentDescription {
        "Display beautiful Quranic verses on your home screen"
    }
}
