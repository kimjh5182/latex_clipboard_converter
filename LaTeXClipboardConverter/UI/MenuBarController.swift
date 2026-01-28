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
    private var spinnerIndex = 0
    
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
            if let image = NSImage(systemSymbolName: "function", accessibilityDescription: "LaTeX Converter") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "ƒ"
            }
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
        Version 1.2.0
        
        Automatically converts LaTeX formula images in your clipboard to LaTeX code using Pix2Tex.
        
        Supported engine:
        • Pix2Tex (Free, Local & Smart)
        
        —
        
        Thank you for always loving me, Yeonsu.
        I hope this helps you with your studies, even if just a little. 🐾
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
        
        // 고양이 발바닥(pawprint) 테마 적용
        let symbolName = settings.isEnabled ? "pawprint.fill" : "pawprint"
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Smart Cat LaTeX") {
            image.isTemplate = true // 시스템 테마에 맞춰 색상 자동 변경
            statusItem?.button?.image = image
            statusItem?.button?.title = ""
        }
    }
    
    func setProcessing(_ processing: Bool) {
        isProcessing = processing
        processingTimer?.invalidate()
        
        if processing {
            spinnerIndex = 0
            processingTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                // 돋보기로 스캔하는 고양이 눈/돋보기 이모지 조합으로 애니메이션 효과
                let frames = ["🔍", "🐱", "✨", "🎓"]
                self.spinnerIndex = (self.spinnerIndex + 1) % frames.count
                self.statusItem?.button?.image = nil
                self.statusItem?.button?.title = frames[self.spinnerIndex]
            }
        } else {
            statusItem?.button?.title = ""
            updateStatusTitle()
        }
    }
}

extension MenuBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        updateMenuState()
    }
}
