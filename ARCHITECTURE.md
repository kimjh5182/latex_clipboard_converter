# LaTeX Clipboard Converter - Architecture Design

## Project Overview

A macOS menu bar application that monitors the clipboard for images containing LaTeX mathematical formulas and automatically converts them to LaTeX code.

### User Flow
1. User takes a screenshot (⌘⇧4) of a LaTeX equation
2. Image is automatically copied to clipboard
3. App detects the clipboard change
4. App analyzes if image contains LaTeX formula
5. App converts image to LaTeX code using OCR
6. App replaces clipboard content with LaTeX text
7. User can paste LaTeX code directly

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

### Image-to-LaTeX Conversion: Multiple Options

#### Option 1: Claude Vision API (RECOMMENDED for MVP)
**Pros:**
- Excellent accuracy for LaTeX formulas
- Simple API integration
- No local model required
- Supports complex equations
- Can handle handwritten formulas

**Cons:**
- Requires API key
- Internet connection required
- Cost: ~$0.003 per image (Claude 3.5 Sonnet)

**Implementation:**
```swift
// Send image to Claude with prompt:
// "Convert this mathematical formula image to LaTeX code. 
//  Return ONLY the LaTeX code without explanation."
```

#### Option 2: Mathpix API
**Pros:**
- Specialized for math OCR
- Very high accuracy
- Fast processing

**Cons:**
- $19.99 setup fee
- $0.002 per image after free tier
- 1000 free requests/month then paid

#### Option 3: Pix2Text (Open Source)
**Pros:**
- Free and open source
- Local processing (privacy)
- No API costs

**Cons:**
- Requires Python runtime
- Needs model downloads (~500MB)
- More complex integration
- May need GPU for good performance

#### Option 4: VikParuchuri/texify (Open Source)
**Pros:**
- Free and open source
- Good accuracy
- Active development

**Cons:**
- Requires Python/PyTorch
- Model size: ~1GB
- Complex setup

### Recommended Approach: Hybrid
1. **MVP**: Start with Claude Vision API
   - Fast development
   - Excellent results
   - Easy to test

2. **Future**: Add Pix2Text as local option
   - For users who want privacy
   - For offline usage
   - For cost savings at scale

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
**Responsibility:** Determine if image contains LaTeX formula
```swift
class ImageAnalyzer {
    func containsLatexFormula(_ image: NSImage) async -> Bool
    // Could use simple heuristics or ML
}
```

### 3. LatexConverter
**Responsibility:** Convert image to LaTeX code
```swift
protocol LatexConverter {
    func convert(_ image: NSImage) async throws -> String
}

class ClaudeLatexConverter: LatexConverter {
    private let apiKey: String
    func convert(_ image: NSImage) async throws -> String
}

class MathpixLatexConverter: LatexConverter {
    private let apiKey: String
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
    var converterType: ConverterType // Claude, Mathpix, Local
    var apiKey: String?
    var pollingInterval: TimeInterval
}
```

## Application Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        Menu Bar App                          │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Status Icon: 📐 (enabled) / 📐̸ (disabled)            │ │
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
│  • Quick heuristic check (optional)                          │
│  • Validate image format                                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    LatexConverter                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Claude     │  │   Mathpix    │  │   Pix2Text   │      │
│  │   Vision     │  │     API      │  │    (Local)   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   ClipboardWriter                            │
│  • Write LaTeX string to NSPasteboard                        │
│  • Show notification (optional)                              │
└─────────────────────────────────────────────────────────────┘
```

## User Interface

### Menu Bar Icon
- **Enabled**: 📐 (ruler/math symbol)
- **Disabled**: 📐̸ (crossed out)
- **Processing**: 🔄 (spinner)

### Menu Items
```
📐 LaTeX Clipboard Converter
├── ✓ Enabled / ☐ Disabled
├── ───────────────────────
├── Converter: Claude Vision ▶
│   ├── ● Claude Vision API
│   ├── ○ Mathpix API
│   └── ○ Local (Pix2Text)
├── ───────────────────────
├── Settings...
├── About
└── Quit
```

### Settings Window
```
┌─────────────────────────────────────────┐
│  LaTeX Clipboard Converter Settings     │
├─────────────────────────────────────────┤
│                                          │
│  Conversion Engine:                      │
│  ○ Claude Vision API                     │
│  ○ Mathpix API                           │
│  ○ Local (Pix2Text)                      │
│                                          │
│  API Key: [____________________] [Test]  │
│                                          │
│  Monitoring:                             │
│  [✓] Start at login                      │
│  [✓] Show notifications                  │
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
Pass to ImageAnalyzer
```

### Image to LaTeX Conversion
```
NSImage
    ↓
Convert to PNG/JPEG data
    ↓
Base64 encode (for API)
    ↓
Send to Claude/Mathpix API
    ↓
Receive LaTeX string
    ↓
Validate LaTeX syntax
    ↓
Write to clipboard
```

## Error Handling

### Scenarios
1. **No API key configured**
   - Show notification: "Please configure API key in Settings"
   - Open settings window

2. **API request failed**
   - Show notification: "Failed to convert image"
   - Keep original image in clipboard
   - Log error for debugging

3. **Invalid image format**
   - Silently ignore
   - Don't process

4. **Rate limit exceeded**
   - Show notification: "Rate limit exceeded, try again later"
   - Temporarily disable monitoring (5 minutes)

5. **No LaTeX detected**
   - Keep original image in clipboard
   - Optional: Show notification "No formula detected"

## Performance Considerations

### Battery Efficiency
- Use 0.5-1 second polling interval (not 0.1s)
- Only check changeCount, not actual content
- Suspend monitoring when on battery < 20%
- Use efficient image encoding

### Memory Management
- Don't keep image history in memory
- Release NSImage after processing
- Use weak references in closures
- Limit concurrent API requests to 1

### Network Efficiency
- Compress images before sending to API
- Cache recent conversions (optional)
- Timeout requests after 10 seconds

## Security & Privacy

### API Keys
- Store in macOS Keychain (not UserDefaults)
- Never log API keys
- Encrypt in memory if possible

### Image Data
- Don't store images permanently
- Don't send to API if user disabled
- Clear clipboard history on quit

### Permissions
- Request Accessibility permissions (for clipboard monitoring)
- Explain why permissions are needed

## Development Phases

### Phase 1: MVP (Week 1-2)
- [x] Research and architecture design
- [ ] Basic Swift app with menu bar icon
- [ ] NSPasteboard monitoring
- [ ] Claude Vision API integration
- [ ] Basic clipboard write functionality
- [ ] Simple enable/disable toggle

### Phase 2: Polish (Week 3)
- [ ] Settings window with API key input
- [ ] Notifications for success/failure
- [ ] Error handling
- [ ] App icon design
- [ ] Launch at login option

### Phase 3: Advanced (Week 4+)
- [ ] Add Mathpix API support
- [ ] Add local Pix2Text option
- [ ] Conversion history (optional)
- [ ] Keyboard shortcuts
- [ ] Advanced settings (polling interval, etc.)

### Phase 4: Distribution
- [ ] Code signing
- [ ] Notarization
- [ ] DMG installer
- [ ] GitHub releases
- [ ] Documentation

## File Structure

```
LaTeXClipboardConverter/
├── LaTeXClipboardConverter.xcodeproj
├── LaTeXClipboardConverter/
│   ├── App/
│   │   ├── LaTeXClipboardConverterApp.swift
│   │   └── AppDelegate.swift
│   ├── Core/
│   │   ├── ClipboardMonitor.swift
│   │   ├── ImageAnalyzer.swift
│   │   └── ClipboardWriter.swift
│   ├── Converters/
│   │   ├── LatexConverter.swift (protocol)
│   │   ├── ClaudeLatexConverter.swift
│   │   ├── MathpixLatexConverter.swift
│   │   └── Pix2TextConverter.swift (future)
│   ├── UI/
│   │   ├── MenuBarController.swift
│   │   ├── SettingsView.swift
│   │   └── AboutView.swift
│   ├── Utilities/
│   │   ├── SettingsManager.swift
│   │   ├── KeychainHelper.swift
│   │   └── NotificationHelper.swift
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   └── Info.plist
│   └── Extensions/
│       ├── NSImage+Extensions.swift
│       └── String+LaTeX.swift
├── Tests/
│   └── LaTeXClipboardConverterTests/
├── README.md
├── LICENSE
└── .gitignore
```

## Dependencies

### Swift Packages
- None required for MVP (use URLSession for API calls)

### Optional Future Dependencies
- **KeychainAccess**: Easier keychain management
- **LaunchAtLogin**: Simplify launch at login
- **Sparkle**: Auto-update framework

## API Integration Details

### Claude Vision API

**Endpoint:** `https://api.anthropic.com/v1/messages`

**Request:**
```json
{
  "model": "claude-3-5-sonnet-20241022",
  "max_tokens": 1024,
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "image",
          "source": {
            "type": "base64",
            "media_type": "image/png",
            "data": "<base64_encoded_image>"
          }
        },
        {
          "type": "text",
          "text": "Convert this mathematical formula image to LaTeX code. Return ONLY the LaTeX code without any explanation, markdown formatting, or additional text. If there are multiple formulas, separate them with newlines."
        }
      ]
    }
  ]
}
```

**Headers:**
```
x-api-version: 2023-06-01
anthropic-version: 2023-06-01
content-type: application/json
x-api-key: <API_KEY>
```

**Response:**
```json
{
  "content": [
    {
      "type": "text",
      "text": "\\int_{0}^{\\infty} e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}"
    }
  ]
}
```

**Cost:** ~$3 per 1000 images (Claude 3.5 Sonnet)

### Mathpix API

**Endpoint:** `https://api.mathpix.com/v3/text`

**Request:**
```json
{
  "src": "data:image/png;base64,<base64_encoded_image>",
  "formats": ["latex_simplified"],
  "data_options": {
    "include_asciimath": false,
    "include_latex": true
  }
}
```

**Headers:**
```
app_id: <APP_ID>
app_key: <APP_KEY>
Content-Type: application/json
```

**Response:**
```json
{
  "latex_simplified": "\\int_{0}^{\\infty} e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}",
  "confidence": 0.99
}
```

**Cost:** $0.002 per image (after 1000 free/month)

## Testing Strategy

### Unit Tests
- ClipboardMonitor: changeCount detection
- ImageAnalyzer: formula detection logic
- LatexConverter: API response parsing
- ClipboardWriter: pasteboard writing

### Integration Tests
- End-to-end: image → LaTeX → clipboard
- API mocking for offline tests
- Error handling scenarios

### Manual Testing
- Screenshot various LaTeX formulas
- Test with different image formats
- Test with non-formula images
- Test error scenarios (no internet, invalid API key)

## Success Metrics

### MVP Success Criteria
- [ ] App runs in menu bar
- [ ] Detects clipboard image changes
- [ ] Converts simple LaTeX formulas (>80% accuracy)
- [ ] Writes LaTeX to clipboard
- [ ] Can be enabled/disabled
- [ ] Handles errors gracefully

### Quality Metrics
- Conversion accuracy: >90%
- Response time: <3 seconds
- Battery impact: <1% per hour
- Memory usage: <50MB
- Crash-free rate: >99%

## Future Enhancements

### v1.1
- [ ] Conversion history viewer
- [ ] Keyboard shortcut to trigger conversion
- [ ] Support for multiple clipboard formats (text + image)

### v1.2
- [ ] Batch conversion mode
- [ ] Custom LaTeX templates
- [ ] Integration with LaTeX editors (Overleaf, TeXShop)

### v2.0
- [ ] Handwriting recognition
- [ ] Chemistry formula support (SMILES)
- [ ] Diagram to TikZ conversion
- [ ] iOS companion app

## References

### Research Sources
1. **NSPasteboard Monitoring:**
   - https://betterprogramming.pub/watch-nspasteboard-swift-4-fad29d2f874e
   - https://github.com/kyle-n/OnPasteboardChange
   - https://github.com/hisaac/PasteboardPublisher

2. **LaTeX OCR Solutions:**
   - Claude Vision API: https://docs.anthropic.com/claude/docs
   - Mathpix: https://mathpix.com/pricing/api
   - Pix2Text: https://github.com/breezedeus/Pix2Text
   - Texify: https://github.com/VikParuchuri/texify

3. **macOS Menu Bar Apps:**
   - https://github.com/lahdekorpi/klipsustreamer
   - https://github.com/ognistik/macrowhisper

### API Documentation
- Claude API: https://docs.anthropic.com/claude/reference/messages_post
- Mathpix API: https://mathpix.com/docs/convert/overview

## License

MIT License (to be decided)

## Contributors

- Initial Design: 2026-01-27
