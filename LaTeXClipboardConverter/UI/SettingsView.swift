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
    
    // 테마 컬러 정의 (Principal Designer Pick)
    let chalkboardColor = Color(red: 0.1, green: 0.15, blue: 0.25) // 네이비 칠판
    let chalkWhite = Color(red: 0.9, green: 0.9, blue: 0.85) // 분필 색상
    let catOrange = Color.orange
    
    var body: some View {
        ZStack {
            // 1. 칠판 배경
            chalkboardColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 2. 타이틀 (분필 스타일)
                Text("Smart Cat & LaTeX")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(chalkWhite)
                    .padding(.top, 25)
                
                Text("똑똑한 고양이의 수학 교실")
                    .font(.caption)
                    .foregroundColor(chalkWhite.opacity(0.7))
                    .padding(.bottom, 15)
                
                Divider().background(chalkWhite.opacity(0.3))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        // 3. 컨버터 정보 (칠판 낙서 컨셉)
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Scanning Engine", systemImage: "magnifyingglass.circle.fill")
                                .font(.headline)
                                .foregroundColor(catOrange)
                            
                            HStack {
                                Image(systemName: "pawprint.fill")
                                    .foregroundColor(catOrange)
                                Text("Pix2Tex (Local & Smart)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(chalkWhite)
                            }
                            
                            Text("고양이가 로컬에서 수식을 직접 분석합니다. 외부 유출 걱정 마세요!")
                                .font(.caption)
                                .foregroundColor(chalkWhite.opacity(0.6))
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        
                        // 4. 선호도 설정
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Preferences")
                                .font(.headline)
                                .foregroundColor(catOrange)
                            
                            Toggle("로그인할 때 고양이 깨우기 (Auto-start)", isOn: $launchAtLogin)
                                .foregroundColor(chalkWhite)
                                .toggleStyle(SwitchToggleStyle(tint: catOrange))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("클립보드 관찰 주기:")
                                    Spacer()
                                    Text("\(pollingInterval, specifier: "%.1f")초")
                                        .bold()
                                }
                                .foregroundColor(chalkWhite)
                                
                                Slider(value: $pollingInterval, in: 0.1...2.0, step: 0.1)
                                    .accentColor(catOrange)
                            }
                        }
                    }
                    .padding()
                }
                
                // 5. 하단 버튼 및 고양이 푸터
                HStack {
                    // 고양이 느낌의 문구
                    Text("🐾 Meow-thematics!")
                        .font(.footnote)
                        .foregroundColor(chalkWhite.opacity(0.4))
                    
                    Spacer()
                    
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(chalkWhite.opacity(0.6))
                    
                    Button(action: {
                        saveSettings()
                    }) {
                        Text("Save Settings")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(catOrange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                .background(Color.black.opacity(0.2))
            }
        }
        .frame(width: 450, height: 500)
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
