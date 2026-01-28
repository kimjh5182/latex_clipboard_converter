import Cocoa

final class Pix2TexConverter: LatexConverter {
    private let pythonPath: String?
    
    init() {
        let paths = [
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/usr/bin/python3"
        ]
        pythonPath = paths.first { FileManager.default.fileExists(atPath: $0) }
    }
    
    func convert(_ image: NSImage) async throws -> String {
        guard let pythonPath = pythonPath else {
            print("[Pix2TexConverter] Python not found")
            throw LatexConverterError.pythonNotInstalled
        }
        
        guard let imageData = imageToData(image) else {
            print("[Pix2TexConverter] Failed to encode image")
            throw LatexConverterError.imageEncodingFailed
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let imagePath = tempDir.appendingPathComponent("latex_ocr_temp.png")
        
        do {
            try imageData.write(to: imagePath)
        } catch {
            print("[Pix2TexConverter] Failed to write temp image: \(error)")
            throw LatexConverterError.imageEncodingFailed
        }
        
        defer {
            try? FileManager.default.removeItem(at: imagePath)
        }
        
        print("[Pix2TexConverter] Running pix2tex on \(imagePath.path)")
        
        let script = """
        import sys
        sys.stdout.reconfigure(encoding='utf-8')
        from PIL import Image
        from pix2tex.cli import LatexOCR
        model = LatexOCR()
        img = Image.open('\(imagePath.path)')
        result = model(img)
        print(result)
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = ["-c", script]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("[Pix2TexConverter] Failed to run Python: \(error)")
            throw LatexConverterError.apiError(statusCode: -1, message: "Python execution failed: \(error.localizedDescription)")
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        if process.terminationStatus != 0 {
            let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            print("[Pix2TexConverter] Python error: \(errorOutput)")
            
            if errorOutput.contains("No module named") && (errorOutput.contains("pix2tex") || errorOutput.contains("PIL")) {
                throw LatexConverterError.dependencyMissing
            }
            
            throw LatexConverterError.apiError(statusCode: Int(process.terminationStatus), message: "Conversion failed. Check console for details.")
        }
        
        guard let output = String(data: outputData, encoding: .utf8) else {
            throw LatexConverterError.responseParsingFailed("Invalid output encoding")
        }
        
        let latex = output.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if latex.isEmpty {
            throw LatexConverterError.noLatexDetected
        }
        
        print("[Pix2TexConverter] Success: \(latex)")
        return latex
    }
    
    private func imageToData(_ image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }
        return pngData
    }
}
