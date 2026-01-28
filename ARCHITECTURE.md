# LaTeX Clipboard Converter - Architecture Design

## Project Overview

A macOS menu bar application that monitors the clipboard for images containing LaTeX mathematical formulas and automatically converts them to LaTeX code using Pix2Tex (local, offline processing).

### User Flow
1. User takes a screenshot (⌘⇧4) of a LaTeX equation
2. Image is automatically copied to clipboard
3. App detects the clipboard change
4. App converts image to LaTeX code using Pix2Tex
5. App replaces clipboard content with LaTeX text
6. User can paste LaTeX code directly

## Technology Stack

### Programming Language: Swift
**Rationale:**
- Native macOS integration (NSPasteboard, NSStatusBar)
- Best performance and battery efficiency
- Direct access to system APIs
- SwiftUI for modern UI development
- No runtime dependencies

### Clipboard Monitoring: NSPasteboard
**Implementation:**
- Use `NSPasteboard.general.changeCount` polling
- Timer-based monitoring (every 0.5-1 second)
- Efficient: only checks changeCount, not content
- Pattern from successful apps: OnPasteboardChange, ClipboardMonitor

**Code Pattern:**
```swift
private var lastChangeCount = NSPasteboard.general.changeCount
private var timer: Timer?

func startMonitoring() {
    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
        let currentCount = NSPasteboard.general.changeCount
        if currentCount != self?.lastChangeCount {
            self?.lastChangeCount = currentCount
            self?.handleClipboardChange()
        }
    }
}
```

### Image-to-LaTeX Conversion: Pix2Tex

**Chosen Solution: Pix2Tex (Open Source)**

**Pros:**
- Free and open source
- Local processing (privacy)
- No API costs
- No internet required after model download
- Good accuracy for printed formulas

**Cons:**
- Requires Python runtime
- Needs model downloads (~500MB)
- First run is slow (model loading)

**Implementation:**
```swift
// Execute pix2tex CLI via Process
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
process.arguments = ["-c", "from pix2tex.cli import LatexOCR; ..."]
```

## Architecture Components

### 1. ClipboardMonitor
**Responsibility:** Monitor clipboard for changes
```swift
class ClipboardMonitor {
    private var lastChangeCount: Int
    private var timer: Timer?
    var onClipboardChange: ((NSImage?) -> Void)?
    
    func startMonitoring()
    func stopMonitoring()
    private func handleClipboardChange()
}
```

### 2. ImageAnalyzer
**Responsibility:** Validate image format
```swift
class ImageAnalyzer {
    func isValidImage(_ image: NSImage) -> Bool
}
```

### 3. LatexConverter
**Responsibility:** Convert image to LaTeX code
```swift
protocol LatexConverter {
    func convert(_ image: NSImage) async throws -> String
}

class Pix2TexConverter: LatexConverter {
    func convert(_ image: NSImage) async throws -> String
}
```

### 4. ClipboardWriter
**Responsibility:** Write LaTeX code back to clipboard
```swift
class ClipboardWriter {
    func writeLatex(_ latex: String)
}
```

### 5. MenuBarController
**Responsibility:** Menu bar UI and app lifecycle
```swift
class MenuBarController {
    private var statusItem: NSStatusItem?
    private var monitor: ClipboardMonitor
    private var isEnabled: Bool
    
    func setupMenuBar()
    func toggleMonitoring()
    func showSettings()
}
```

### 6. SettingsManager
**Responsibility:** Store user preferences
```swift
class SettingsManager {
    var isEnabled: Bool
    var pollingInterval: TimeInterval
    var launchAtLogin: Bool
}
```

## Application Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        Menu Bar App                          │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Status Icon: ƒ (enabled) / [ƒ] (disabled) / ◐ (busy)  │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    ClipboardMonitor                          │
│  • Timer (0.5s interval)                                     │
│  • Check NSPasteboard.changeCount                            │
│  • Detect image type changes                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     ImageAnalyzer                            │
│  • Validate image format                                     │
│  • Check image size                                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Pix2TexConverter                           │
│  • Save image to temp file                                   │
│  • Execute Python pix2tex                                    │
│  • Parse LaTeX output                                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   ClipboardWriter                            │
│  • Write LaTeX string to NSPasteboard                        │
│  • Show notification                                         │
└─────────────────────────────────────────────────────────────┘
```

## User Interface

### Menu Bar Icon
- **Enabled**: `ƒ` (function symbol via SF Symbols)
- **Disabled**: `ƒ○` (with circle indicator)
- **Processing**: `◐ ◓ ◑ ◒` (spinner animation)

### Menu Items
```
ƒ LaTeX Clipboard Converter
├── ✓ Enabled / ☐ Disabled
├── ☐ Launch at Login
├── ───────────────────────
├── Settings...
├── About
├── ───────────────────────
└── Quit
```

### Settings Window
```
┌─────────────────────────────────────────┐
│  Settings                               │
├─────────────────────────────────────────┤
│                                          │
│  Conversion Engine:                      │
│  ✓ Pix2Tex (Free, Local)                │
│                                          │
│  Preferences:                            │
│  [✓] Launch at Login                     │
│                                          │
│  Polling Interval: [0.5] seconds         │
│                                          │
│  [Cancel]              [Save]            │
└─────────────────────────────────────────┘
```

## Data Flow

### Clipboard Change Detection
```
NSPasteboard.changeCount changed
    ↓
Check if content is image
    ↓
Extract NSImage from pasteboard
    ↓
Pass to Pix2TexConverter
```

### Image to LaTeX Conversion
```
NSImage
    ↓
Save to temp PNG file
    ↓
Execute pix2tex Python script
    ↓
Read LaTeX output from stdout
    ↓
Write to clipboard
```

## Error Handling

### Scenarios
1. **Python not installed**
   - Show notification: "Python 3 is required"
   - Provide installation instructions

2. **pix2tex not installed**
   - Show notification: "Please install pix2tex"
   - Command: `pip3 install pix2tex`

3. **Conversion failed**
   - Show notification: "Failed to convert image"
   - Keep original image in clipboard
   - Log error for debugging

4. **Invalid image format**
   - Silently ignore
   - Don't process

## Performance Considerations

### Battery Efficiency
- Use 0.5-1 second polling interval (not 0.1s)
- Only check changeCount, not actual content
- Suspend monitoring when disabled
- Use efficient image encoding

### Memory Management
- Don't keep image history in memory
- Release NSImage after processing
- Use weak references in closures
- Clean up temp files

### CPU Efficiency
- Pix2tex runs in separate process
- Main app stays responsive during conversion
- Loading indicator shows processing state

## Security & Privacy

### Local Processing
- All conversion happens locally
- No data sent to external servers
- No API keys required

### Permissions
- Clipboard access (standard)
- Python execution

## File Structure

```
LaTeXClipboardConverter/
├── LaTeXClipboardConverter.xcodeproj
├── LaTeXClipboardConverter/
│   ├── App/
│   │   ├── LaTeXClipboardConverterApp.swift
│   │   ├── AppDelegate.swift
│   │   └── main.swift
│   ├── Core/
│   │   ├── ClipboardMonitor.swift
│   │   ├── ImageAnalyzer.swift
│   │   └── ClipboardWriter.swift
│   ├── Converters/
│   │   ├── LatexConverter.swift (protocol)
│   │   └── Pix2TexConverter.swift
│   ├── UI/
│   │   ├── MenuBarController.swift
│   │   ├── SettingsView.swift
│   │   └── SettingsWindowController.swift
│   ├── Utilities/
│   │   ├── SettingsManager.swift
│   │   ├── NotificationManager.swift
│   │   └── LaunchAtLoginHelper.swift
│   └── Resources/
│       └── Info.plist
├── README.md
├── USAGE_GUIDE.md
└── ARCHITECTURE.md
```

## Dependencies

### Required
- Python 3.8+
- pix2tex package (`pip3 install pix2tex`)

### Swift Packages
- None required (use native APIs)

## References

### Research Sources
1. **NSPasteboard Monitoring:**
   - https://betterprogramming.pub/watch-nspasteboard-swift-4-fad29d2f874e
   - https://github.com/kyle-n/OnPasteboardChange

2. **LaTeX OCR:**
   - Pix2Tex: https://github.com/lukas-blecher/LaTeX-OCR

3. **macOS Menu Bar Apps:**
   - https://github.com/lahdekorpi/klipsustreamer

## License

MIT License
