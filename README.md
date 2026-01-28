# LaTeX Clipboard Converter

A macOS menu bar application that automatically converts images of LaTeX mathematical formulas to LaTeX code.

## Features

- 📐 **Automatic Conversion**: Monitors clipboard for images and converts LaTeX formulas to code
- 🤖 **Claude Vision AI**: Uses Anthropic's Claude 3.5 Sonnet for accurate formula recognition
- ⚡ **Fast & Efficient**: Lightweight background process with minimal battery impact
- 🎯 **Menu Bar Integration**: Simple toggle on/off from menu bar
- 🚀 **Launch at Login**: Optional automatic startup
- ⚙️ **Configurable**: Adjust polling interval and API settings

## How It Works

1. Take a screenshot of a LaTeX formula (⌘⇧4)
2. Image is automatically copied to clipboard
3. App detects the image and converts it to LaTeX
4. LaTeX code replaces the image in clipboard
5. Paste the LaTeX code anywhere (⌘V)

## Requirements

- macOS 11.0 or later
- Claude API key (get one at https://console.anthropic.com/)

## Installation

### Option 1: Build from Source

1. Clone this repository:
```bash
git clone https://github.com/yourusername/latex-clipboard-converter.git
cd latex-clipboard-converter
```

2. Open in Xcode:
```bash
open LaTeXClipboardConverter.xcodeproj
```

3. Build and run (⌘R)

### Option 2: Download Release

Download the latest `.app` from the [Releases](https://github.com/yourusername/latex-clipboard-converter/releases) page.

## Setup

1. Launch the app
2. Click the menu bar icon (📐)
3. Select "Settings..."
4. Enter your Claude API key
5. Click "Test" to verify the key works
6. Click "Save"

## Usage

### Basic Usage

1. Enable monitoring from the menu bar (✓ Enabled)
2. Screenshot any LaTeX formula
3. The clipboard will automatically contain the LaTeX code

### Settings

- **API Key**: Your Claude API key for formula conversion
- **Launch at Login**: Start app automatically when you log in
- **Polling Interval**: How often to check clipboard (0.1-2.0 seconds)

### Menu Bar

- **✓ Enabled / ☐ Disabled**: Toggle clipboard monitoring
- **☐ Launch at Login**: Toggle auto-start
- **Settings...**: Open settings window
- **About**: App information
- **Quit**: Exit the application

## API Costs

The app uses Claude 3.5 Sonnet API:
- Cost: ~$3 per 1,000 images
- Free tier: Check Anthropic's current pricing

## Architecture

Built with:
- **Swift**: Native macOS development
- **SwiftUI**: Modern UI framework
- **NSPasteboard**: Clipboard monitoring
- **Claude Vision API**: Image-to-LaTeX conversion
- **ServiceManagement**: Launch at login

## Project Structure

```
LaTeXClipboardConverter/
├── App/
│   ├── LaTeXClipboardConverterApp.swift
│   └── AppDelegate.swift
├── Core/
│   ├── ClipboardMonitor.swift
│   ├── ImageAnalyzer.swift
│   └── ClipboardWriter.swift
├── Converters/
│   ├── LatexConverter.swift
│   └── ClaudeLatexConverter.swift
├── UI/
│   ├── MenuBarController.swift
│   ├── SettingsView.swift
│   └── SettingsWindowController.swift
└── Utilities/
    ├── SettingsManager.swift
    └── LaunchAtLoginHelper.swift
```

## Development

### Building

```bash
xcodebuild -project LaTeXClipboardConverter.xcodeproj \
           -scheme LaTeXClipboardConverter \
           build
```

### Running

```bash
xcodebuild -project LaTeXClipboardConverter.xcodeproj \
           -scheme LaTeXClipboardConverter \
           -configuration Debug \
           run
```

## Troubleshooting

### App doesn't detect clipboard changes

- Check that monitoring is enabled (✓ Enabled in menu)
- Verify the app has Accessibility permissions in System Preferences
- Try adjusting the polling interval in Settings

### API key not working

- Verify your API key is correct
- Check your internet connection
- Ensure you have API credits remaining
- Use the "Test" button in Settings to diagnose

### Conversion is inaccurate

- Ensure the image is clear and high-resolution
- Try screenshotting just the formula (not surrounding text)
- Check that the formula is standard LaTeX notation

## Privacy

- Images are sent to Claude API for processing
- No images are stored locally
- API key is stored securely in UserDefaults
- No telemetry or analytics

## Future Enhancements

- [ ] Support for Mathpix API
- [ ] Local OCR with Pix2Text
- [ ] Conversion history
- [ ] Batch conversion mode
- [ ] Keyboard shortcuts
- [ ] Chemistry formula support
- [ ] Handwriting recognition

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

## Credits

- Built with [Claude](https://www.anthropic.com/claude) by Anthropic
- Inspired by [Mathpix Snip](https://mathpix.com/)

## Support

For issues and questions:
- Open an issue on GitHub
- Email: your.email@example.com

---

Made with ❤️ for the LaTeX community
