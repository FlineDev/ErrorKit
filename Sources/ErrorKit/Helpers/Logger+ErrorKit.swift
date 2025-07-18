#if canImport(OSLog)
import OSLog

@available(macOS 11, *)
extension Logger {
   /// Logs a debug message with complete error chain description
   ///
   /// ```swift
   /// Logger().debug("Operation failed", error: error)
   /// ```
   ///
   /// - Parameters:
   ///   - message: The main log message
   ///   - error: The error to include using its complete chain description for debugging
   public func debug(_ message: String, error: some Error) {
      let normalizedMessage = self.normalizeMessage(message)
      self.debug("\(normalizedMessage):\n\(ErrorKit.errorChainDescription(for: error))")
   }

   /// Logs an info message with complete error chain description
   ///
   /// ```swift
   /// Logger().info("User action failed", error: error)
   /// ```
   ///
   /// - Parameters:
   ///   - message: The main log message
   ///   - error: The error to include using its complete chain description for debugging
   public func info(_ message: String, error: some Error) {
      let normalizedMessage = self.normalizeMessage(message)
      self.info("\(normalizedMessage):\n\(ErrorKit.errorChainDescription(for: error))")
   }

   /// Logs a notice with complete error chain description
   ///
   /// ```swift
   /// Logger().notice("Important operation failed", error: error)
   /// ```
   ///
   /// - Parameters:
   ///   - message: The main log message
   ///   - error: The error to include using its complete chain description for debugging
   public func notice(_ message: String, error: some Error) {
      let normalizedMessage = self.normalizeMessage(message)
      self.notice("\(normalizedMessage):\n\(ErrorKit.errorChainDescription(for: error))")
   }

   /// Logs a warning with complete error chain description
   ///
   /// ```swift
   /// Logger().warning("Recoverable error occurred", error: error)
   /// ```
   ///
   /// - Parameters:
   ///   - message: The main log message
   ///   - error: The error to include using its complete chain description for debugging
   public func warning(_ message: String, error: some Error) {
      let normalizedMessage = self.normalizeMessage(message)
      self.warning("\(normalizedMessage):\n\(ErrorKit.errorChainDescription(for: error))")
   }

   /// Logs an error message with complete error chain description
   ///
   /// ```swift
   /// Logger().error("Upload failed", error: error)
   /// ```
   ///
   /// - Parameters:
   ///   - message: The main log message
   ///   - error: The error to include using its complete chain description for debugging
   public func error(_ message: String, error: some Error) {
      let normalizedMessage = self.normalizeMessage(message)
      self.error("\(normalizedMessage):\n\(ErrorKit.errorChainDescription(for: error))")
   }

   /// Logs a fault with complete error chain description
   ///
   /// ```swift
   /// Logger().fault("Critical system error", error: error)
   /// ```
   ///
   /// - Parameters:
   ///   - message: The main log message
   ///   - error: The error to include using its complete chain description for debugging
   public func fault(_ message: String, error: some Error) {
      let normalizedMessage = self.normalizeMessage(message)
      self.fault("\(normalizedMessage):\n\(ErrorKit.errorChainDescription(for: error))")
   }

   /// Normalizes a log message by removing trailing punctuation and whitespace
   ///
   /// This ensures consistent formatting regardless of how the user writes the message:
   /// - "Upload failed" → "Upload failed"
   /// - "Upload failed:" → "Upload failed"
   /// - "Upload failed: " → "Upload failed"
   /// - "Upload failed." → "Upload failed"
   ///
   /// - Parameter message: The original message to normalize
   /// - Returns: The normalized message without trailing punctuation or whitespace
   private func normalizeMessage(_ message: String) -> String {
      return message.trimmingCharacters(in: .whitespacesAndNewlines)
         .trimmingCharacters(in: CharacterSet(charactersIn: ":"))
   }
}
#endif
