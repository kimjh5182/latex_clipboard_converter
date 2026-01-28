import Cocoa

/// Errors that can occur during LaTeX conversion
enum LatexConverterError: Error, LocalizedError {
    case noApiKeyConfigured
    case networkTimeout
    case networkError(Error)
    case apiRateLimitExceeded
    case invalidApiKey
    case apiError(statusCode: Int, message: String)
    case responseParsingFailed(String)
    case imageEncodingFailed
    case noLatexDetected
    case dependencyMissing
    case pythonNotInstalled
    
    var errorDescription: String? {
        switch self {
        case .noApiKeyConfigured:
            return "No API key configured. Please set your API key in Settings."
        case .networkTimeout:
            return "Network request timed out. Please try again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiRateLimitExceeded:
            return "API rate limit exceeded. Please try again later."
        case .invalidApiKey:
            return "Invalid API key. Please check your API key in Settings."
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .responseParsingFailed(let details):
            return "Failed to parse API response: \(details)"
        case .imageEncodingFailed:
            return "Failed to encode image for API request."
        case .noLatexDetected:
            return "No LaTeX formula detected in the image."
        case .dependencyMissing:
            return "SETUP_REQUIRED"
        case .pythonNotInstalled:
            return "PYTHON_NOT_INSTALLED"
        }
    }
}

/// Protocol for LaTeX conversion services
protocol LatexConverter {
    /// Convert an image containing a mathematical formula to LaTeX code
    /// - Parameter image: The NSImage containing the formula
    /// - Returns: The LaTeX code as a string
    /// - Throws: LatexConverterError if conversion fails
    func convert(_ image: NSImage) async throws -> String
}
