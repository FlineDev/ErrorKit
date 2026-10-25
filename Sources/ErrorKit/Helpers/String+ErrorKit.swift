import Foundation

extension String {
   #if canImport(CryptoKit)
      // On Apple platforms, use the modern localization API with Bundle.module
      static func localized(key: StaticString, defaultValue: String.LocalizationValue) -> String {
         String(
            localized: key,
            defaultValue: defaultValue,
            bundle: Bundle.module
         )
      }
   #else
      // On non-Apple platforms, just return the default value (the English translation)
      static func localized(key: StaticString, defaultValue: String) -> String {
         defaultValue
      }
   #endif
}

extension String.StringInterpolation {
   /// Interpolates an error using its user-friendly message.
   ///
   /// Uses ``ErrorKit.userFriendlyMessage(for:)`` to provide clear, actionable error descriptions
   /// suitable for displaying to users. For nested errors, returns the message from the root cause.
   ///
   /// ```swift
   /// showAlert("Operation failed: \(error)")
   /// ```
   ///
   /// - Parameter error: The error to interpolate using its user-friendly message
   mutating public func appendInterpolation(_ error: some Error) {
      self.appendInterpolation(ErrorKit.userFriendlyMessage(for: error))
   }

   /// Interpolates an error using its complete chain description for debugging.
   ///
   /// Uses ``ErrorKit/errorChainDescription(for:indent:)`` to show the full error hierarchy,
   /// type information, and nested structure. Ideal for logging and debugging.
   ///
   /// ```swift
   /// print("Operation failed with:\n\(chain: error)")
   /// // Operation failed with:
   /// // DatabaseError
   /// // └─ FileError
   /// //    └─ PermissionError.denied(permission: "~/Downloads/Profile.png")
   /// //       └─ userFriendlyMessage: "Access to ~/Downloads/Profile.png was declined..."
   /// ```
   ///
   /// - Parameter error: The error to interpolate using its complete chain description
   mutating public func appendInterpolation(chain error: some Error) {
      self.appendInterpolation(ErrorKit.errorChainDescription(for: error))
   }

   /// Interpolates an error using its complete chain description for debugging.
   ///
   /// Uses ``ErrorKit/errorChainDescription(for:indent:)`` to show the full error hierarchy,
   /// type information, and nested structure. Ideal for logging and debugging.
   ///
   /// ```swift
   /// print("Operation failed with:\n\(chain: error)")
   /// // Operation failed with:
   /// // DatabaseError
   /// // └─ FileError
   /// //    └─ PermissionError.denied(permission: "~/Downloads/Profile.png")
   /// //       └─ userFriendlyMessage: "Access to ~/Downloads/Profile.png was declined..."
   /// ```
   ///
   /// - Parameter error: The error to interpolate using its complete chain description
   ///
   /// - NOTE: Alias for ``appendInterpolation(chain:)``.
   mutating public func appendInterpolation(debug error: some Error) {
      self.appendInterpolation(chain: error)
   }
}
