import Cocoa

class ClipboardWriter {
    func writeLatex(_ latex: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(latex, forType: .string)
        print("[ClipboardWriter] Wrote LaTeX to clipboard: \(latex)")
    }
    
    func writeImage(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        print("[ClipboardWriter] Wrote image to clipboard")
    }
}
