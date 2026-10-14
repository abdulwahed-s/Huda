import CoreText
import Foundation

enum MacWidgetFonts {
    private static let registration: Void = {
        for name in ["Amiri-Regular", "Amiri-Bold"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()

    static func register() {
        _ = registration
    }
}
