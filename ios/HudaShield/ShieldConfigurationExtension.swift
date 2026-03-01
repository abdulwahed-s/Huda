import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return makeShieldConfig()
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return makeShieldConfig()
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return makeShieldConfig()
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return makeShieldConfig()
    }
    
    private func makeShieldConfig() -> ShieldConfiguration {
        let progressInfo = readProgressInfo()
        let accentColor = UIColor(red: 36.0/255.0, green: 51.0/255.0, blue: 64.0/255.0, alpha: 1.0) // #243340
        let titleColor = UIColor.label
        let subtitleColor = UIColor.secondaryLabel
        
        let title = ShieldConfiguration.Label(
            text: localizedString("miqaat_lock_title"),
            color: titleColor
        )
        
        let subtitle: ShieldConfiguration.Label
        if progressInfo.isCompleted {
            subtitle = ShieldConfiguration.Label(
                text: localizedString("miqaat_lock_goal_completed"),
                color: subtitleColor
            )
        } else if progressInfo.goalMinutes > 0 {
            let remaining = max(0, progressInfo.goalMinutes * 60 - progressInfo.accumulatedSeconds)
            let mins = remaining / 60
            let secs = remaining % 60
            subtitle = ShieldConfiguration.Label(
                text: String(format: localizedString("miqaat_lock_goal_remaining"), mins, secs),
                color: subtitleColor
            )
        } else {
            subtitle = ShieldConfiguration.Label(
                text: localizedString("miqaat_lock_goal_default"),
                color: subtitleColor
            )
        }
        
        let primaryButton = ShieldConfiguration.Label(
            text: localizedString("miqaat_lock_open_huda"),
            color: .white
        )
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: createMosqueIcon(),
            title: title,
            subtitle: subtitle,
            primaryButtonLabel: primaryButton,
            primaryButtonBackgroundColor: accentColor
        )
    }
    
    private func localizedString(_ key: String) -> String {
        return NSLocalizedString(key, bundle: Bundle(for: type(of: self)), comment: "")
    }
    
    private struct ProgressInfo {
        var accumulatedSeconds: Int = 0
        var goalMinutes: Int = 0
        var isCompleted: Bool = false
    }
    
    private func readProgressInfo() -> ProgressInfo {
        guard let defaults = UserDefaults(suiteName: "group.com.aw.huda") else {
            return ProgressInfo()
        }
        
        return ProgressInfo(
            accumulatedSeconds: defaults.integer(forKey: "miqaat_accumulated_seconds"),
            goalMinutes: defaults.integer(forKey: "miqaat_goal_minutes"),
            isCompleted: defaults.bool(forKey: "miqaat_goal_completed")
        )
    }

    private func createMosqueIcon() -> UIImage? {
        let size = CGSize(width: 88, height: 88)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let circleColor = UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor(red: 36.0/255.0, green: 51.0/255.0, blue: 64.0/255.0, alpha: 0.15)
                } else {
                    return UIColor(red: 36.0/255.0, green: 51.0/255.0, blue: 64.0/255.0, alpha: 0.10)
                }
            }
            
            let strokeColor = UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor(red: 36.0/255.0, green: 51.0/255.0, blue: 64.0/255.0, alpha: 0.25)
                } else {
                    return UIColor(red: 36.0/255.0, green: 51.0/255.0, blue: 64.0/255.0, alpha: 0.20)
                }
            }
            
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
            
            circleColor.setFill()
            path.fill()
            
            strokeColor.setStroke()
            path.lineWidth = 2
            path.stroke()
            
            let emoji = "🕌" as NSString
            let font = UIFont.systemFont(ofSize: 40)
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: font
            ]
            
            let textSize = emoji.size(withAttributes: textAttributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            emoji.draw(in: textRect, withAttributes: textAttributes)
        }
    }
}
