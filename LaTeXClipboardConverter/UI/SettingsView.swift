import SwiftUI
import AppKit

struct PastableTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.bezelStyle = .roundedBezel
        textField.font = NSFont.systemFont(ofSize: 13)
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: PastableTextField
        
        init(_ parent: PastableTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }
    }
}

struct SettingsView: View {
    @State private var claudeApiKey: String = ""
    @State private var simpleTexToken: String = ""
    @State private var converterType: String = "claude"
    @State private var launchAtLogin: Bool = false
    @State private var pollingInterval: Double = 0.5
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isTestingAPI: Bool = false
    
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 20)
                .padding(.bottom, 10)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Conversion Engine
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Conversion Engine")
                            .font(.headline)
                        
                        Picker("Engine:", selection: $converterType) {
                            Text("SimpleTex (Free, Online)").tag("simpletex")
                            Text("Pix2Tex (Free, Local)").tag("pix2tex")
                            Text("Claude Vision API (Paid)").tag("claude")
                        }
                        .pickerStyle(.radioGroup)
                    }
                    
                    Divider()
                    
                    // API Configuration
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Configuration")
                            .font(.headline)
                        
                        if converterType == "simpletex" {
                            VStack(alignment: .leading, spacing: 4) {
                                TextEditor(text: $simpleTexToken)
                                    .font(.system(size: 12, design: .monospaced))
                                    .frame(height: 60)
                                    .border(Color.gray.opacity(0.3), width: 1)
                                
                                Text("Get token: simpletex.net/user/center > User Authorization Token")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else if converterType == "pix2tex" {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("No API key needed!")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.green)
                                
                                Text("Pix2Tex runs locally on your Mac. First run may be slow (downloading model).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Requires: pip3 install pix2tex")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                TextEditor(text: $claudeApiKey)
                                    .font(.system(size: 12, design: .monospaced))
                                    .frame(height: 60)
                                    .border(Color.gray.opacity(0.3), width: 1)
                                
                                Text("Get key: console.anthropic.com")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Preferences
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferences")
                            .font(.headline)
                        
                        Toggle("Launch at Login", isOn: $launchAtLogin)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Polling Interval:")
                                Spacer()
                                Text("\(pollingInterval, specifier: "%.1f")s")
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $pollingInterval, in: 0.1...2.0, step: 0.1)
                            
                            Text("How often to check clipboard for changes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    saveSettings()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 500, height: 450)
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        let settings = SettingsManager.shared
        claudeApiKey = settings.claudeApiKey ?? ""
        simpleTexToken = settings.simpleTexToken ?? ""
        converterType = settings.converterType
        launchAtLogin = settings.launchAtLogin
        pollingInterval = settings.pollingInterval
    }
    
    private func saveSettings() {
        let settings = SettingsManager.shared
        let converterChanged = settings.converterType != converterType
        
        settings.claudeApiKey = claudeApiKey.isEmpty ? nil : claudeApiKey
        settings.simpleTexToken = simpleTexToken.isEmpty ? nil : simpleTexToken
        settings.converterType = converterType
        settings.launchAtLogin = launchAtLogin
        settings.pollingInterval = pollingInterval
        
        print("[SettingsView] Settings saved, converter: \(converterType)")
        
        if converterChanged {
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.updateConverter()
                print("[SettingsView] Converter hot-reloaded to: \(converterType)")
            }
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    SettingsView()
}
