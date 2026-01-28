import Cocoa

class ImageAnalyzer {
    func containsLatexFormula(_ image: NSImage) async -> Bool {
        // For MVP, we'll do basic validation
        // In future, this could use ML or heuristics
        return true
    }
    
    func validateImage(_ image: NSImage) -> Bool {
        return image.size.width > 0 && image.size.height > 0
    }
}
