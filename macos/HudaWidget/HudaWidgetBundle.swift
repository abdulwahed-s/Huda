import SwiftUI
import WidgetKit

@main
struct HudaMacWidgetBundle: WidgetBundle {
    var body: some Widget {
        HudaWidget()
        HudaPrayerWidget()
    }
}
