import Foundation
import ServiceManagement

class SettingsManager {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let isEnabled = "isEnabled"
        static let pollingInterval = "pollingInterval"
        static let converterType = "converterType"
        static let claudeApiKey = "claudeApiKey"
        static let simpleTexToken = "simpleTexToken"
        static let launchAtLogin = "launchAtLogin"
    }
    
    var isEnabled: Bool {
        get { defaults.bool(forKey: Keys.isEnabled) }
        set { defaults.set(newValue, forKey: Keys.isEnabled) }
    }
    
    var pollingInterval: TimeInterval {
        get {
            let interval = defaults.double(forKey: Keys.pollingInterval)
            return interval > 0 ? interval : 0.5
        }
        set { defaults.set(newValue, forKey: Keys.pollingInterval) }
    }
    
    var converterType: String {
        get { defaults.string(forKey: Keys.converterType) ?? "claude" }
        set { defaults.set(newValue, forKey: Keys.converterType) }
    }
    
    var claudeApiKey: String? {
        get { defaults.string(forKey: Keys.claudeApiKey) }
        set { defaults.set(newValue, forKey: Keys.claudeApiKey) }
    }
    
    var simpleTexToken: String? {
        get { defaults.string(forKey: Keys.simpleTexToken) }
        set { defaults.set(newValue, forKey: Keys.simpleTexToken) }
    }
    
    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set {
            defaults.set(newValue, forKey: Keys.launchAtLogin)
            setLaunchAtLoginSystemPreference(newValue)
        }
    }
    
    private func setLaunchAtLoginSystemPreference(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if enabled {
                    try service.register()
                    print("[SettingsManager] Successfully registered app for launch at login")
                } else {
                    try service.unregister()
                    print("[SettingsManager] Successfully unregistered app from launch at login")
                }
            } catch {
                print("[SettingsManager] Error setting launch at login: \(error.localizedDescription)")
            }
        } else {
            print("[SettingsManager] macOS 13+ required for launch at login support")
        }
    }
    
    init() {
        if !defaults.bool(forKey: "hasInitialized") {
            isEnabled = true
            pollingInterval = 0.5
            converterType = "claude"
            defaults.set(true, forKey: "hasInitialized")
        }
    }
}
