# LaTeX Clipboard Converter

A macOS menu bar application that automatically converts images of LaTeX mathematical formulas to LaTeX code using **Pix2Tex** (local, free, no API key required).

## Features

- **Free & Local**: Uses Pix2Tex for offline conversion - no API costs
- **Automatic Conversion**: Monitors clipboard for images and converts LaTeX formulas to code
- **Fast & Efficient**: Lightweight background process with minimal battery impact
- **Menu Bar Integration**: Simple toggle on/off from menu bar
- **Launch at Login**: Optional automatic startup
- **Privacy First**: All processing happens locally on your Mac

## How It Works

1. Take a screenshot of a LaTeX formula (⌘⇧4)
2. Image is automatically copied to clipboard
3. App detects the image and converts it to LaTeX
4. LaTeX code replaces the image in clipboard
5. Paste the LaTeX code anywhere (⌘V)

## Requirements

- macOS 11.0 or later
- Python 3.8+
- pix2tex package

## Installation

### Step 1: Install Pix2Tex (Required)

Before using the app, you need to install the pix2tex Python package:

```bash
# Install pix2tex
pip3 install pix2tex

# Or if you use conda
conda install -c conda-forge pix2tex
```

**First run note**: The first conversion may take longer as pix2tex downloads the AI model (~500MB).

### Step 2: Install the App

#### Option A: Download DMG (Recommended)

1. Download `LaTeXClipboardConverter.dmg` from the [Releases](https://github.com/kimjh5182/latex_clipboard_converter/releases) page
2. Open the DMG file
3. Drag the app to Applications folder
4. Eject the DMG

> **Note for macOS Security**: Since this app is not signed by a registered Apple developer, you may see a "Malicious software" warning. To open it:
> 1. Right-click (or Control-click) the app in your Applications folder.
> 2. Select **Open** from the menu.
> 3. Click **Open** again in the dialog box.
> 4. After this, the app will open normally.

#### Option B: Build from Source

```bash
git clone https://github.com/kimjh5182/latex_clipboard_converter.git
cd latex-clipboard-converter
open LaTeXClipboardConverter.xcodeproj
# Build and run (⌘R)
```

## Verify Pix2Tex Installation

Run this command to verify pix2tex is installed correctly:

```bash
python3 -c "from pix2tex.cli import LatexOCR; print('pix2tex is ready!')"
```

If you see "pix2tex is ready!", you're good to go!

## Usage

### Basic Usage

1. Launch the app (appears in menu bar as `ƒ` icon)
2. Enable monitoring (should show checkmark next to "Enabled")
3. Screenshot any LaTeX formula (⌘⇧4)
4. The clipboard will automatically contain the LaTeX code
5. Paste anywhere (⌘V)

### Menu Bar Options

- **✓ Enabled / Disabled**: Toggle clipboard monitoring
- **Launch at Login**: Toggle auto-start
- **Settings...**: Adjust polling interval
- **About**: App information
- **Quit**: Exit the application

### Settings

- **Launch at Login**: Start app automatically when you log in
- **Polling Interval**: How often to check clipboard (0.1-2.0 seconds)

## Troubleshooting

### "Python not installed" error

Install Python 3:

```bash
# Using Homebrew
brew install python3

# Or download from python.org
```

### "pix2tex not found" error

```bash
pip3 install pix2tex
```

If using a virtual environment, make sure it's activated or install globally.

### Conversion is slow

- First run downloads the model (~500MB) - this is normal
- Subsequent conversions should be faster
- Try closing other resource-intensive apps

### App doesn't detect clipboard changes

- Check that monitoring is enabled (✓ Enabled in menu)
- Try adjusting the polling interval in Settings
- Restart the app

### Conversion is inaccurate

- Ensure the image is clear and high-resolution
- Try screenshotting just the formula (not surrounding text)
- Check that the formula is standard LaTeX notation

## Project Structure

```
LaTeXClipboardConverter/
├── App/
│   ├── LaTeXClipboardConverterApp.swift
│   ├── AppDelegate.swift
│   └── main.swift
├── Core/
│   ├── ClipboardMonitor.swift
│   ├── ImageAnalyzer.swift
│   └── ClipboardWriter.swift
├── Converters/
│   ├── LatexConverter.swift
│   └── Pix2TexConverter.swift
├── UI/
│   ├── MenuBarController.swift
│   ├── SettingsView.swift
│   └── SettingsWindowController.swift
└── Utilities/
    ├── SettingsManager.swift
    ├── NotificationManager.swift
    └── LaunchAtLoginHelper.swift
```

## Architecture

Built with:

- **Swift**: Native macOS development
- **SwiftUI**: Modern UI framework
- **NSPasteboard**: Clipboard monitoring
- **Pix2Tex**: Local image-to-LaTeX conversion
- **ServiceManagement**: Launch at login

## Privacy

- All processing happens locally - images never leave your Mac
- No API keys required
- No telemetry or analytics
- No data collection

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

## Credits

- [Pix2Tex](https://github.com/lukas-blecher/LaTeX-OCR) by Lukas Blecher
- Inspired by [Mathpix Snip](https://mathpix.com/)

---

Made with ❤️ for the LaTeX community
