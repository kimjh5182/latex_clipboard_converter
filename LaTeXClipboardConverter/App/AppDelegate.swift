import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var clipboardMonitor: ClipboardMonitor?
    private var latexConverter: LatexConverter?
    private var clipboardWriter: ClipboardWriter?
    private var isProcessing = false {
        didSet {
            menuBarController?.setProcessing(isProcessing)
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupEditMenu()
        
        clipboardMonitor = ClipboardMonitor()
        latexConverter = createConverter()
        clipboardWriter = ClipboardWriter()
        menuBarController = MenuBarController(monitor: clipboardMonitor!)
        
        clipboardMonitor?.onClipboardChange = { [weak self] image in
            self?.handleClipboardChange(image: image)
        }
        
        let settings = SettingsManager.shared
        if settings.isEnabled {
            clipboardMonitor?.startMonitoring()
        }
        
        print("[AppDelegate] Application launched with Pix2Tex converter")
    }
    
    private func createConverter() -> LatexConverter {
        print("[AppDelegate] Using Pix2Tex converter (local)")
        return Pix2TexConverter()
    }
    
    private func setupEditMenu() {
        let mainMenu = NSMenu()
        
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
        
        NSApp.mainMenu = mainMenu
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationShouldTerminate(withoutSavingTo sender: NSApplication) -> NSApplication.TerminateReply {
        clipboardMonitor?.stopMonitoring()
        return .terminateNow
    }
    
    private func handleClipboardChange(image: NSImage?) {
        guard let image = image else {
            print("[AppDelegate] Clipboard changed but no image")
            return
        }
        
        guard !isProcessing else {
            print("[AppDelegate] Already processing, skipping")
            return
        }
        
        print("[AppDelegate] Processing clipboard image")
        
        isProcessing = true
        
        Task {
            await convertImageToLatex(image)
            await MainActor.run {
                isProcessing = false
            }
        }
    }
    
    private func convertImageToLatex(_ image: NSImage) async {
        guard let converter = latexConverter else {
            print("[AppDelegate] No converter available")
            return
        }
        
        do {
            let latex = try await converter.convert(image)
            print("[AppDelegate] Conversion successful: \(latex)")
            
            await MainActor.run {
                clipboardMonitor?.stopMonitoring()
                clipboardWriter?.writeLatex(latex)
                NotificationManager.shared.showSuccess(latex: latex)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    if SettingsManager.shared.isEnabled {
                        self?.clipboardMonitor?.startMonitoring()
                    }
                }
            }
        } catch LatexConverterError.pythonNotInstalled {
            print("[AppDelegate] Python not installed - showing setup dialog")
            await MainActor.run {
                NotificationManager.shared.showPythonNotInstalled()
            }
        } catch LatexConverterError.dependencyMissing {
            print("[AppDelegate] Dependency missing - showing setup dialog")
            await MainActor.run {
                NotificationManager.shared.showSetupRequired()
            }
        } catch let error as LatexConverterError {
            print("[AppDelegate] Conversion failed: \(error.localizedDescription)")
            await MainActor.run {
                NotificationManager.shared.showError(message: error.localizedDescription)
            }
        } catch {
            print("[AppDelegate] Unexpected error: \(error)")
            await MainActor.run {
                NotificationManager.shared.showError(message: error.localizedDescription)
            }
        }
    }
}
