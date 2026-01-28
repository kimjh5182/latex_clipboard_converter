import Cocoa

final class SimpleTexConverter: LatexConverter {
    private let apiEndpoint = "https://server.simpletex.cn/api/latex_ocr_turbo"
    private let timeoutInterval: TimeInterval = 15.0
    
    func convert(_ image: NSImage) async throws -> String {
        guard let token = SettingsManager.shared.simpleTexToken, !token.isEmpty else {
            print("[SimpleTexConverter] No token configured")
            throw LatexConverterError.noApiKeyConfigured
        }
        
        guard let imageData = imageToData(image) else {
            print("[SimpleTexConverter] Failed to encode image")
            throw LatexConverterError.imageEncodingFailed
        }
        
        print("[SimpleTexConverter] Sending request to SimpleTex API")
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        request.timeoutInterval = timeoutInterval
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "token")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await performRequest(request)
        return try parseResponse(data: data, response: response)
    }
    
    private func imageToData(_ image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }
        return pngData
    }
    
    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            print("[SimpleTexConverter] Request timed out")
            throw LatexConverterError.networkTimeout
        } catch {
            print("[SimpleTexConverter] Network error: \(error)")
            throw LatexConverterError.networkError(error)
        }
    }
    
    private func parseResponse(data: Data, response: URLResponse) throws -> String {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LatexConverterError.responseParsingFailed("Invalid response type")
        }
        
        print("[SimpleTexConverter] Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[SimpleTexConverter] API error: \(errorMessage)")
            throw LatexConverterError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LatexConverterError.responseParsingFailed("Invalid JSON")
        }
        
        if let res = json["res"] as? [String: Any],
           let latex = res["latex"] as? String {
            let result = latex.trimmingCharacters(in: .whitespacesAndNewlines)
            print("[SimpleTexConverter] Success: \(result)")
            return result
        }
        
        if let latex = json["latex"] as? String {
            let result = latex.trimmingCharacters(in: .whitespacesAndNewlines)
            print("[SimpleTexConverter] Success: \(result)")
            return result
        }
        
        let rawResponse = String(data: data, encoding: .utf8) ?? ""
        print("[SimpleTexConverter] Unexpected response: \(rawResponse)")
        throw LatexConverterError.responseParsingFailed("Could not extract LaTeX")
    }
}
