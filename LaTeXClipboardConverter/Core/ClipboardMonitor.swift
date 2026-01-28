import Cocoa

class ClipboardMonitor {
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?
    private var isMonitoring = false
    
    var onClipboardChange: ((NSImage?) -> Void)?
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboardChange()
        }
        
        print("[ClipboardMonitor] Started monitoring")
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        
        timer?.invalidate()
        timer = nil
        
        print("[ClipboardMonitor] Stopped monitoring")
    }
    
    private func checkClipboardChange() {
        let currentCount = NSPasteboard.general.changeCount
        
        if currentCount != lastChangeCount {
            lastChangeCount = currentCount
            handleClipboardChange()
        }
    }
    
    private func handleClipboardChange() {
        let pasteboard = NSPasteboard.general
        
        // Check if clipboard contains an image
        if let image = extractImage(from: pasteboard) {
            print("[ClipboardMonitor] Image detected in clipboard")
            onClipboardChange?(image)
        } else {
            print("[ClipboardMonitor] Clipboard changed but no image found")
            onClipboardChange?(nil)
        }
    }
    
    private func extractImage(from pasteboard: NSPasteboard) -> NSImage? {
        // Check for NSImage type
        if let image = pasteboard.readObjects(forClasses: [NSImage.self]) as? [NSImage],
           let firstImage = image.first {
            return firstImage
        }
        
        // Check for file URLs that might be images
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self]) as? [NSURL] {
            for url in fileURLs {
                if let image = NSImage(contentsOf: url as URL) {
                    return image
                }
            }
        }
        
        return nil
    }
}
