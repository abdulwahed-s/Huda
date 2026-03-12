import Foundation
import Flutter

#if canImport(FamilyControls)
import FamilyControls
import ManagedSettings
#endif

@available(iOS 16.0, *)
class MiqaatLockManager: NSObject {
    
    static let shared = MiqaatLockManager()
    
    #if canImport(FamilyControls)
    private let store = ManagedSettingsStore()
    private var isAuthorized = false
    private var selectedAppsSelection: FamilyActivitySelection?
    private let selectionKey = "miqaat_lock_selection"
    #endif
    
    private let defaults = UserDefaults.standard
    private let settingsKey = "miqaat_lock_ios_settings"
    
    private let appGroupId = "group.com.aw.huda"
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupId)
    }
    
    private let completedSlotsKey = "miqaat_completed_slots"
    private let completedSlotsDateKey = "miqaat_completed_slots_date"
    
    private override init() {
        super.init()
        #if canImport(FamilyControls)
        loadSavedSelection()
        #endif
    }
    
    func requestAuthorization() async -> Bool {
        #if canImport(FamilyControls)
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = true
            return true
        } catch {
            print("MiqaatLock: Authorization failed: \(error)")
            return false
        }
        #else
        return false
        #endif
    }
    
    func checkAuthorizationStatus() -> Bool {
        #if canImport(FamilyControls)
        return AuthorizationCenter.shared.authorizationStatus == .approved
        #else
        return false
        #endif
    }
    
    #if canImport(FamilyControls)
    func setSelectedApps(_ selection: FamilyActivitySelection) {
        selectedAppsSelection = selection
        saveSelection(selection)
        
        if let settings = loadSettings(), settings["isEnabled"] as? Bool == true {
            applyRestrictions()
        }
    }
    
    func getSelectedApps() -> FamilyActivitySelection? {
        return selectedAppsSelection
    }
    
    func hasSelectedApps() -> Bool {
        guard let selection = selectedAppsSelection else { return false }
        return !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
    }
    
    func getSelectedAppsCount() -> [String: Any] {
        guard let selection = selectedAppsSelection else {
            return ["appCount": 0, "categoryCount": 0, "total": 0]
        }
        let appCount = selection.applicationTokens.count
        let categoryCount = selection.categoryTokens.count
        return ["appCount": appCount, "categoryCount": categoryCount, "total": appCount + categoryCount]
    }
    
    func clearSelectedApps() {
        selectedAppsSelection = nil
        defaults.removeObject(forKey: selectionKey)
        removeRestrictions()
    }
    
    private func saveSelection(_ selection: FamilyActivitySelection) {
        do {
            let data = try JSONEncoder().encode(selection)
            defaults.set(data, forKey: selectionKey)
        } catch {
            print("MiqaatLock: Failed to save selection: \(error)")
        }
    }
    
    private func loadSavedSelection() {
        guard let data = defaults.data(forKey: selectionKey) else { return }
        do {
            selectedAppsSelection = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            print("MiqaatLock: Failed to load saved selection: \(error)")
        }
    }
    #endif
    
    func getInstalledApps() -> [[String: Any]] {
        return []
    }
    
    func updateSettings(isEnabled: Bool, lockedApps: [String], timeSlots: [[String: Any]], goalDuration: Int) {
        let settings: [String: Any] = [
            "isEnabled": isEnabled,
            "lockedApps": lockedApps,
            "timeSlots": timeSlots,
            "goalDurationMinutes": goalDuration
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: settings) {
            defaults.set(data, forKey: settingsKey)
        }
        
        sharedDefaults?.set(goalDuration, forKey: "miqaat_goal_duration")
        sharedDefaults?.synchronize()
        
        if isEnabled {
            applyRestrictions()
        } else {
            removeRestrictions()
        }
    }
    
    func loadSettings() -> [String: Any]? {
        guard let data = defaults.data(forKey: settingsKey),
              let settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return settings
    }
    
    private func applyRestrictions() {
        #if canImport(FamilyControls)
        guard isAuthorized || checkAuthorizationStatus() else { return }
        
        guard isInActiveTimeSlot() else {
            removeRestrictions()
            return
        }
        
        if let activeSlotId = getActiveTimeSlotId(), isTimeSlotCompleted(activeSlotId) {
            removeRestrictions()
            return
        }
        
        if let selection = selectedAppsSelection {
            store.shield.applications = selection.applicationTokens
            store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
            store.shield.webDomains = selection.webDomainTokens
            print("MiqaatLock: Applied shield to \(selection.applicationTokens.count) apps, \(selection.categoryTokens.count) categories")
        } else {
            print("MiqaatLock: No apps selected to block")
        }
        #endif
    }
    
    func removeRestrictions() {
        #if canImport(FamilyControls)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        #endif
    }
    
    private func isInActiveTimeSlot() -> Bool {
        return getActiveTimeSlotId() != nil
    }
    
    private func getActiveTimeSlotId() -> String? {
        guard let settings = loadSettings(),
              let timeSlots = settings["timeSlots"] as? [[String: Any]],
              !timeSlots.isEmpty else {
            return nil
        }
        
        let calendar = Calendar.current
        let now = Date()
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let dayOfWeek = calendar.component(.weekday, from: now)
        let isoDayOfWeek = dayOfWeek == 1 ? 7 : dayOfWeek - 1
        
        for slot in timeSlots {
            guard let startHour = slot["startHour"] as? Int,
                  let startMinute = slot["startMinute"] as? Int,
                  let endHour = slot["endHour"] as? Int,
                  let endMinute = slot["endMinute"] as? Int else {
                continue
            }
            
            let slotId = slot["id"] as? String ?? ""
            
            if let weekdays = slot["weekdays"] as? [Int], !weekdays.isEmpty {
                if !weekdays.contains(isoDayOfWeek) {
                    continue
                }
            }
            
            let startMinutes = startHour * 60 + startMinute
            let endMinutes = endHour * 60 + endMinute
            
            if endMinutes < startMinutes {
                if currentMinutes >= startMinutes || currentMinutes < endMinutes {
                    return slotId
                }
            } else {
                if currentMinutes >= startMinutes && currentMinutes < endMinutes {
                    return slotId
                }
            }
        }
        
        return nil
    }
    
    func completeTimeSlot(timeSlotId: String) {
        var completedSlots = getCompletedTimeSlotIds()
        completedSlots.insert(timeSlotId)
        
        let today = todayDateString()
        defaults.set(Array(completedSlots), forKey: completedSlotsKey)
        defaults.set(today, forKey: completedSlotsDateKey)
        
        sharedDefaults?.set(Array(completedSlots), forKey: completedSlotsKey)
        sharedDefaults?.set(today, forKey: completedSlotsDateKey)
        sharedDefaults?.synchronize()
        
        removeRestrictions()
    }
    
    func isTimeSlotCompleted(_ slotId: String) -> Bool {
        return getCompletedTimeSlotIds().contains(slotId)
    }
    
    private func getCompletedTimeSlotIds() -> Set<String> {
        let today = todayDateString()
        let storedDate = defaults.string(forKey: completedSlotsDateKey)
        
        if storedDate != today {
            defaults.removeObject(forKey: completedSlotsKey)
            defaults.set(today, forKey: completedSlotsDateKey)
            return []
        }
        
        let ids = defaults.stringArray(forKey: completedSlotsKey) ?? []
        return Set(ids)
    }
    
    func updateSessionProgress(accumulatedSeconds: Int, goalMinutes: Int, timeSlotId: String, isCompleted: Bool) {
        sharedDefaults?.set(accumulatedSeconds, forKey: "miqaat_accumulated_seconds")
        sharedDefaults?.set(goalMinutes, forKey: "miqaat_goal_minutes")
        sharedDefaults?.set(timeSlotId, forKey: "miqaat_current_slot_id")
        sharedDefaults?.set(isCompleted, forKey: "miqaat_goal_completed")
        sharedDefaults?.synchronize()
    }
    
    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

class MiqaatLockMethodHandler: NSObject {
    
    let channel: FlutterMethodChannel
    
    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "com.aw.huda/miqaat_lock", binaryMessenger: messenger)
        super.init()
        channel.setMethodCallHandler(handle)
    }
    
    private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if #available(iOS 16.0, *) {
            handleiOS16(call: call, result: result)
        } else {
            switch call.method {
            case "isScreenTimeAuthorized":
                result(false)
            case "getInstalledApps":
                result([])
            default:
                result(FlutterError(code: "UNSUPPORTED", message: "Family Controls requires iOS 16+", details: nil))
            }
        }
    }
    
    @available(iOS 16.0, *)
    private func handleiOS16(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let manager = MiqaatLockManager.shared
        
        switch call.method {
        case "isScreenTimeAuthorized":
            result(manager.checkAuthorizationStatus())
            
        case "requestScreenTimeAuthorization":
            Task {
                let authorized = await manager.requestAuthorization()
                DispatchQueue.main.async {
                    result(authorized)
                }
            }
            
        case "getInstalledApps":
            result([])
            
        case "checkPermissions":
            result([
                "screenTimeAuthorized": manager.checkAuthorizationStatus()
            ])
            
        case "updateSettings":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
                return
            }
            
            let isEnabled = args["isEnabled"] as? Bool ?? false
            let lockedApps = args["lockedApps"] as? [String] ?? []
            let timeSlots = args["timeSlots"] as? [[String: Any]] ?? []
            let goalDuration = args["goalDurationMinutes"] as? Int ?? 10
            
            manager.updateSettings(
                isEnabled: isEnabled,
                lockedApps: lockedApps,
                timeSlots: timeSlots,
                goalDuration: goalDuration
            )
            result(true)
            
        case "completeTimeSlot":
            guard let args = call.arguments as? [String: Any],
                  let timeSlotId = args["timeSlotId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing timeSlotId", details: nil))
                return
            }
            manager.completeTimeSlot(timeSlotId: timeSlotId)
            result(true)
            
        case "updateSessionProgress":
            guard let args = call.arguments as? [String: Any] else {
                result(true)
                return
            }
            let accumulatedSeconds = args["accumulatedSeconds"] as? Int ?? 0
            let goalMinutes = args["goalMinutes"] as? Int ?? 0
            let timeSlotId = args["timeSlotId"] as? String ?? ""
            let isCompleted = args["isCompleted"] as? Bool ?? false
            
            manager.updateSessionProgress(
                accumulatedSeconds: accumulatedSeconds,
                goalMinutes: goalMinutes,
                timeSlotId: timeSlotId,
                isCompleted: isCompleted
            )
            result(true)
            
        case "hasSelectedApps":
            result(manager.hasSelectedApps())
            
        case "getSelectedAppsCount":
            result(manager.getSelectedAppsCount())
            
        case "showFamilyActivityPicker":
            DispatchQueue.main.async {
                guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
                    result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not find root view controller", details: nil))
                    return
                }
                
                let pickerVC = FamilyActivityPickerHostingController()
                pickerVC.modalPresentationStyle = .formSheet
                pickerVC.onDismiss = {
                    let hasApps = manager.hasSelectedApps()
                    result(hasApps)
                }
                
                rootVC.present(pickerVC, animated: true)
            }
            
        case "clearSelectedApps":
            manager.clearSelectedApps()
            result(true)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
