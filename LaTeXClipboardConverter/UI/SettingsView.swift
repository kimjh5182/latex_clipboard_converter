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
    @State private var launchAtLogin: Bool = false
    @State private var pollingInterval: Double = 0.5
    
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 20)
                .padding(.bottom, 10)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Conversion Engine")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Pix2Tex (Free, Local)")
                                .font(.system(size: 14, weight: .medium))
                        }
                        
                        Text("Runs locally on your Mac. First run may be slow (downloading model).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Requires: pip3 install pix2tex")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
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
        .frame(width: 400, height: 320)
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        let settings = SettingsManager.shared
        launchAtLogin = settings.launchAtLogin
        pollingInterval = settings.pollingInterval
    }
    
    private func saveSettings() {
        let settings = SettingsManager.shared
        settings.launchAtLogin = launchAtLogin
        settings.pollingInterval = pollingInterval
        
        print("[SettingsView] Settings saved")
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    SettingsView()
}
