import Cocoa

final class ClaudeLatexConverter: LatexConverter {
    private let apiEndpoint = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-20250514"
    private let maxTokens = 1024
    private let timeoutInterval: TimeInterval = 10.0
    
    private let prompt = """
        Convert this mathematical formula image to LaTeX code. \
        Return ONLY the LaTeX code without any explanation, markdown formatting, or additional text. \
        If there are multiple formulas, separate them with newlines.
        """
    
    func convert(_ image: NSImage) async throws -> String {
        guard let apiKey = SettingsManager.shared.claudeApiKey, !apiKey.isEmpty else {
            print("[ClaudeLatexConverter] No API key configured")
            throw LatexConverterError.noApiKeyConfigured
        }
        
        guard let base64Image = encodeImageToBase64(image) else {
            print("[ClaudeLatexConverter] Failed to encode image")
            throw LatexConverterError.imageEncodingFailed
        }
        
        print("[ClaudeLatexConverter] Sending request to Claude API")
        
        let requestBody = buildRequestBody(base64Image: base64Image)
        let request = try buildURLRequest(apiKey: apiKey, body: requestBody)
        
        let (data, response) = try await performRequest(request)
        
        return try parseResponse(data: data, response: response)
    }
    
    private func encodeImageToBase64(_ image: NSImage) -> String? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }
        return pngData.base64EncodedString()
    }
    
    private func buildRequestBody(base64Image: String) -> [String: Any] {
        return [
            "model": model,
            "max_tokens": maxTokens,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/png",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]
    }
    
    private func buildURLRequest(apiKey: String, body: [String: Any]) throws -> URLRequest {
        guard let url = URL(string: apiEndpoint) else {
            throw LatexConverterError.apiError(statusCode: 0, message: "Invalid API endpoint URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeoutInterval
        
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        return request
    }
    
    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            print("[ClaudeLatexConverter] Request timed out")
            throw LatexConverterError.networkTimeout
        } catch {
            print("[ClaudeLatexConverter] Network error: \(error)")
            throw LatexConverterError.networkError(error)
        }
    }
    
    private func parseResponse(data: Data, response: URLResponse) throws -> String {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LatexConverterError.responseParsingFailed("Invalid response type")
        }
        
        print("[ClaudeLatexConverter] Response status: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200:
            return try extractLatexFromResponse(data)
        case 401:
            print("[ClaudeLatexConverter] Invalid API key")
            throw LatexConverterError.invalidApiKey
        case 429:
            print("[ClaudeLatexConverter] Rate limit exceeded")
            throw LatexConverterError.apiRateLimitExceeded
        default:
            let errorMessage = extractErrorMessage(from: data)
            print("[ClaudeLatexConverter] API error: \(errorMessage)")
            throw LatexConverterError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
    }
    
    private func extractLatexFromResponse(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("[ClaudeLatexConverter] Failed to parse response: \(rawResponse)")
            throw LatexConverterError.responseParsingFailed("Could not extract text from response")
        }
        
        let latex = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if latex.isEmpty {
            throw LatexConverterError.noLatexDetected
        }
        
        print("[ClaudeLatexConverter] Successfully extracted LaTeX: \(latex)")
        return latex
    }
    
    private func extractErrorMessage(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            return message
        }
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }
}
