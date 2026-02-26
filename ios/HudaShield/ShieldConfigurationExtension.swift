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
        let accentColor = UIColor(red: 0.0, green: 0.78, blue: 0.65, alpha: 1.0) // teal/emerald
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
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: "moon.stars.fill"),
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
}
