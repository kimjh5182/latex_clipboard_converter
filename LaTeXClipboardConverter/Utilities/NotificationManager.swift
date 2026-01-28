import Cocoa
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {
        requestPermission()
    }
    
    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("[NotificationManager] Notification permission granted")
            } else if let error = error {
                print("[NotificationManager] Permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func showSuccess(latex: String) {
        let content = UNMutableNotificationContent()
        content.title = "LaTeX Converted"
        
        let preview = latex.count > 50 ? String(latex.prefix(50)) + "..." : latex
        content.body = preview
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[NotificationManager] Failed to show notification: \(error)")
            }
        }
    }
    
    func showError(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Conversion Failed"
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[NotificationManager] Failed to show notification: \(error)")
            }
        }
    }
    
    func showSetupRequired() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Setup Required"
            alert.informativeText = """
            pix2tex is not installed.
            
            Open Terminal and run:
            pip3 install pix2tex pillow
            
            Then try again!
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Copy Command")
            alert.addButton(withTitle: "OK")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString("pip3 install pix2tex pillow", forType: .string)
            }
        }
    }
    
    func showPythonNotInstalled() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Python Required"
            alert.informativeText = """
            Python 3 is not installed on your Mac.
            
            Step 1: Install Homebrew (if not installed)
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            Step 2: Install Python
            brew install python3
            
            Step 3: Install pix2tex
            pip3 install pix2tex pillow
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Copy All Commands")
            alert.addButton(withTitle: "OK")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                let commands = """
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                brew install python3
                pip3 install pix2tex pillow
                """
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(commands, forType: .string)
            }
        }
    }
}
