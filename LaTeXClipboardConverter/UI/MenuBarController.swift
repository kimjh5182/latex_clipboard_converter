import Cocoa

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var monitor: ClipboardMonitor
    private var menu: NSMenu?
    private var enabledMenuItem: NSMenuItem?
    private var settingsWindowController: SettingsWindowController?
    private var launchAtLoginMenuItem: NSMenuItem?
    private var isProcessing = false
    private var processingTimer: Timer?
    
    init(monitor: ClipboardMonitor) {
        self.monitor = monitor
        super.init()
        setupMenuBar()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupMenuBar() {
        print("[MenuBarController] Setting up menu bar...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "LaTeX"
            print("[MenuBarController] Status item button created")
        }
        print("[MenuBarController] Status item created: \(statusItem != nil)")
        
        menu = NSMenu()
        menu?.delegate = self
        
        enabledMenuItem = NSMenuItem(
            title: "✓ Enabled",
            action: #selector(toggleMonitoring),
            keyEquivalent: ""
        )
        enabledMenuItem?.target = self
        menu?.addItem(enabledMenuItem!)
        
        launchAtLoginMenuItem = NSMenuItem(
            title: "☐ Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginMenuItem?.target = self
        menu?.addItem(launchAtLoginMenuItem!)
        
        menu?.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu?.addItem(settingsItem)
        
        let aboutItem = NSMenuItem(
            title: "About",
            action: #selector(openAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu?.addItem(aboutItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu?.addItem(quitItem)
        
        statusItem?.menu = menu
        
        updateMenuState()
    }
    
    @objc private func toggleMenu() {
        if let menu = menu, let statusItem = statusItem {
            statusItem.popUpMenu(menu)
        }
    }
    
    @objc private func toggleMonitoring() {
        let settings = SettingsManager.shared
        settings.isEnabled = !settings.isEnabled
        
        if settings.isEnabled {
            monitor.startMonitoring()
        } else {
            monitor.stopMonitoring()
        }
        
        updateMenuState()
    }
    
    @objc private func toggleLaunchAtLogin() {
        let settings = SettingsManager.shared
        settings.launchAtLogin = !settings.launchAtLogin
        updateMenuState()
    }
    
    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func openAbout() {
        let alert = NSAlert()
        alert.messageText = "LaTeX Clipboard Converter"
        alert.informativeText = """
        Version 1.0.0
        
        Automatically converts LaTeX formula images in your clipboard to LaTeX code.
        
        Supported engines:
        • SimpleTex (free, online)
        • Pix2Tex (free, local)
        • Claude Vision API (paid)
        
        —
        
        Thank you for always loving me, Yeonsu.
        I hope this helps you with your studies, even if just a little.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func updateMenuState() {
        let settings = SettingsManager.shared
        enabledMenuItem?.title = settings.isEnabled ? "Enabled" : "Disabled"
        enabledMenuItem?.state = settings.isEnabled ? .on : .off
        updateStatusTitle()
        launchAtLoginMenuItem?.title = "Launch at Login"
        launchAtLoginMenuItem?.state = settings.launchAtLogin ? .on : .off
    }
    
    private func updateStatusTitle() {
        let settings = SettingsManager.shared
        if isProcessing {
            return
        }
        statusItem?.button?.title = settings.isEnabled ? "LaTeX" : "[LaTeX]"
    }
    
    func setProcessing(_ processing: Bool) {
        isProcessing = processing
        processingTimer?.invalidate()
        
        if processing {
            var dotCount = 0
            processingTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
                dotCount = (dotCount + 1) % 4
                let dots = String(repeating: ".", count: dotCount)
                self?.statusItem?.button?.title = "LaTeX" + dots
            }
        } else {
            updateStatusTitle()
        }
    }
}

extension MenuBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        updateMenuState()
    }
}
