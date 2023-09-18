import Foundation

// TODO: replace later with custom type-specific auto-generated error type?
extension NSError {
    public static func generic(code: Int, message: String) -> NSError {
        NSError(domain: Bundle.main.bundleIdentifier ?? "App", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
