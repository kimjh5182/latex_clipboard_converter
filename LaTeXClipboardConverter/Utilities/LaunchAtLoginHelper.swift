import Foundation
import ServiceManagement

class LaunchAtLoginHelper {
    /// Sets whether the app should launch at login
    /// - Parameter enabled: true to enable launch at login, false to disable
    /// - Throws: Error if the operation fails
    static func setLaunchAtLogin(_ enabled: Bool) throws {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if enabled {
                    try service.register()
                    print("[LaunchAtLoginHelper] Successfully registered app for launch at login")
                } else {
                    try service.unregister()
                    print("[LaunchAtLoginHelper] Successfully unregistered app from launch at login")
                }
            } catch {
                print("[LaunchAtLoginHelper] Error setting launch at login: \(error.localizedDescription)")
                throw error
            }
        } else {
            // Fallback for older macOS versions
            print("[LaunchAtLoginHelper] macOS 13+ required for SMAppService. Current version does not support launch at login.")
        }
    }
    
    /// Checks if the app is currently set to launch at login
    /// - Returns: true if launch at login is enabled, false otherwise
    static func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            let isEnabled = status == .enabled
            print("[LaunchAtLoginHelper] Launch at login status: \(isEnabled ? "enabled" : "disabled")")
            return isEnabled
        } else {
            // Fallback for older macOS versions
            print("[LaunchAtLoginHelper] macOS 13+ required for SMAppService. Returning false.")
            return false
        }
    }
}
