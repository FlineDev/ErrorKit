import Foundation
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

public enum ErrorKit {
   /// Provides enhanced, user-friendly, localized error descriptions for a wide range of system errors.
   ///
   /// This function analyzes the given `Error` and returns a clearer, more helpful message than the default system-provided description.
   /// All descriptions are localized, ensuring that users receive messages in their preferred language where available.
   ///
   /// The function uses registered error mappers to generate contextual messages for errors from different frameworks and libraries.
   /// ErrorKit includes built-in mappers for `Foundation`, `CoreData`, `MapKit`, and more.
   /// You can extend ErrorKit's capabilities by registering custom mappers using ``registerMapper(_:)``.
   /// Custom mappers are queried in reverse order, meaning user-provided mappers take precedence over built-in ones.
   ///
   /// The list of user-friendly messages is maintained and regularly improved by the developer community.
   /// Contributions are welcome—if you find bugs or encounter new errors, feel free to submit a pull request (PR) for review.
   ///
   /// - Parameter error: The `Error` instance for which a user-friendly message is needed.
   /// - Returns: A `String` containing an enhanced, localized, user-readable error message.
   ///
   /// ## Usage Example:
   /// ```swift
   /// do {
   ///     // Example network request
   ///     let url = URL(string: "https://example.com")!
   ///     let _ = try Data(contentsOf: url)
   /// } catch {
   ///     print(ErrorKit.userFriendlyMessage(for: error))
   ///     // Output: "You are not connected to the Internet. Please check your connection." (if applicable)
   /// }
   /// ```
   public static func userFriendlyMessage(for error: Error) -> String {
      // Any types conforming to `Throwable` are assumed to already have a good description
      if let throwable = error as? Throwable {
         return throwable.userFriendlyMessage
      }

      // Check if a custom mapping was registered (in reverse order to prefer user-provided over built-in mappings)
      for errorMapper in self.errorMappers.reversed() {
         if let mappedMessage = errorMapper.userFriendlyMessage(for: error) {
            return mappedMessage
         }
      }

      // LocalizedError: The officially recommended error type to conform to in Swift, prefer over NSError
      if let localizedError = error as? LocalizedError {
         return [
            localizedError.errorDescription,
            localizedError.failureReason,
            localizedError.recoverySuggestion,
         ].compactMap(\.self).joined(separator: " ")
      }

      // Default fallback (adds domain & code at least) – since all errors conform to NSError
      let nsError = error as NSError
      return "[\(nsError.domain): \(nsError.code)] \(nsError.localizedDescription)"
   }

   // MARK: - Error Chain

   /// Generates a detailed, hierarchical description of an error chain for debugging purposes.
   ///
   /// This function provides a comprehensive view of nested errors, particularly useful when errors are wrapped through multiple layers
   /// of an application. While ``userFriendlyMessage(for:)`` is designed for end users, this function helps developers understand
   /// the complete error chain during debugging, similar to a stack trace.
   ///
   /// One key advantage of using typed throws with ``Catching`` is that it maintains the full error chain hierarchy, allowing you to trace
   /// exactly where in your application's call stack the error originated. Without this, errors caught from deep within system frameworks
   /// or different modules would lose their context, making it harder to identify the source. The error chain description preserves both
   /// the original error (as the leaf node) and the complete path of error wrapping, effectively reconstructing the error's journey
   /// through your application's layers.
   ///
   /// The combination of nested error types often creates a unique signature that helps pinpoint exactly where in your codebase
   /// the error occurred, without requiring symbolicated crash reports or complex debugging setups. For instance, if you see
   /// `ProfileError` wrapping `DatabaseError` wrapping `FileError`, this specific chain might only be possible in one code path
   /// in your application.
   ///
   /// The output includes:
   /// - The full type hierarchy of nested errors
   /// - Detailed enum case information including associated values
   /// - Type metadata ([Struct] or [Class] for non-enum types)
   /// - User-friendly message at the leaf level
   ///
   /// This is particularly valuable when:
   /// - Using typed throws in Swift 6 wrapping nested errors using ``Catching``
   /// - Debugging complex error flows across multiple modules
   /// - Understanding where and how errors are being wrapped
   /// - Investigating error handling in modular applications
   ///
   /// The structured output format makes it ideal for error analytics and monitoring:
   /// - The entire chain description can be sent to analytics services
   /// - A hash of the string split by ":" and "(" can group similar errors which is provided in ``groupingID(for:)``
   /// - Error patterns can be monitored and analyzed systematically across your user base
   ///
   /// ## Example Output:
   /// ```swift
   /// // For a deeply nested error chain:
   /// StateError
   /// └─ OperationError
   ///    └─ DatabaseError
   ///       └─ FileError
   ///          └─ PermissionError.denied(permission: "~/Downloads/Profile.png")
   ///             └─ userFriendlyMessage: "Access to ~/Downloads/Profile.png was declined."
   /// ```
   ///
   /// ## Usage Example:
   /// ```swift
   /// struct ProfileManager {
   ///     enum ProfileError: Throwable, Catching {
   ///         case validationFailed
   ///         case caught(Error)
   ///     }
   ///
   ///     func updateProfile() throws {
   ///         do {
   ///             try ProfileError.catch {
   ///                 try databaseOperation()
   ///             }
   ///         } catch {
   ///             let chainDescription = ErrorKit.errorChainDescription(for: error)
   ///
   ///             // Log the complete error chain for debugging
   ///             Logger().error("Error updating profile:\n\(chainDescription)")
   ///             // Output might show:
   ///             // ProfileError
   ///             // └─ DatabaseError.connectionFailed
   ///             //    └─ userFriendlyMessage: "Could not connect to the database."
   ///
   ///             // Optional: Send to analytics
   ///             Analytics.logError(
   ///                 identifier: chainDescription.hashValue,
   ///                 details: chainDescription
   ///             )
   ///
   ///             // forward error to handle in caller
   ///             throw error
   ///         }
   ///     }
   /// }
   /// ```
   ///
   /// This output helps developers trace the error's path through the application:
   /// 1. Identifies the entry point (ProfileError)
   /// 2. Shows the underlying cause (DatabaseError.connectionFailed)
   /// 3. Provides the user-friendly message for context (users will report this)
   ///
   /// - Parameters:
   ///    - error: The error to describe, potentially containing nested errors
   ///    - indent: The initial indent string (normally "")
   /// - Returns: A formatted string showing the complete error hierarchy with indentation
   public static func errorChainDescription(for error: Error, indent: String = "") -> String {
      return Self.chainDescription(for: error, indent: indent, enclosingType: type(of: error))
   }

   private static func chainDescription(for error: Error, indent: String, enclosingType: Any.Type?) -> String {
      let mirror = Mirror(reflecting: error)

      // Helper function to format the type name with optional metadata
      func typeDescription(_ error: Error, enclosingType: Any.Type?) -> String {
         let typeName = String(describing: type(of: error))

         // For structs and classes (non-enums), append [Struct] or [Class]
         if mirror.displayStyle != .enum {
            let isClass = Swift.type(of: error) is AnyClass
            return "\(typeName) [\(isClass ? "Class" : "Struct")]"
         } else {
            // For enums, include the full case description with type name
            if let enclosingType {
               return "\(enclosingType).\(error)"
            } else {
               return String(describing: error)
            }
         }
      }

      // Check if this is a nested error (conforms to Catching and has a caught case)
      if let caughtError = mirror.children.first(where: { $0.label == "caught" })?.value as? Error {
         let currentErrorType = type(of: error)
         let nextIndent = indent + "   "
         return """
            \(currentErrorType)
            \(indent)└─ \(Self.chainDescription(for: caughtError, indent: nextIndent, enclosingType: type(of: caughtError)))
            """
      } else {
         // This is a leaf node
         return """
            \(typeDescription(error, enclosingType: enclosingType))
            \(indent)└─ userFriendlyMessage: \"\(Self.userFriendlyMessage(for: error))\"
            """
      }
   }

   // MARK: - Grouping ID

   /// Generates a stable identifier that groups similar errors based on their type structure.
   ///
   /// While ``errorChainDescription(for:)`` provides a detailed view of an error chain including all parameters and messages,
   /// this function creates a consistent hash that only considers the error type hierarchy. This allows grouping similar errors
   /// that differ only in their specific parameters or localized messages.
   ///
   /// This is particularly useful for:
   /// - Error analytics and aggregation
   /// - Identifying common error patterns across your user base
   /// - Grouping similar errors in logging systems
   /// - Creating stable identifiers for error monitoring
   ///
   /// For example, these two errors would generate the same grouping ID despite having different parameters:
   /// ```swift
   /// // Error 1:
   /// DatabaseError
   /// └─ FileError.notFound(path: "/Users/john/data.db")
   ///    └─ userFriendlyMessage: "Could not find database file."
   ///    // Grouping ID: "3f9d2a"
   ///
   /// // Error 2:
   /// DatabaseError
   /// └─ FileError.notFound(path: "/Users/jane/backup.db")
   ///    └─ userFriendlyMessage: "Database file missing."
   ///    // Grouping ID: "3f9d2a"
   /// ```
   ///
   /// ## Usage Example:
   /// ```swift
   /// struct ErrorMonitor {
   ///     static func track(_ error: Error) {
   ///         // Get a stable ID that ignores specific parameters
   ///         let groupID = ErrorKit.groupingID(for: error) // e.g. "3f9d2a"
   ///
   ///         // Get the full description for detailed logging
   ///         let details = ErrorKit.errorChainDescription(for: error)
   ///
   ///         // Track error occurrence with analytics
   ///         Analytics.logError(
   ///             identifier: groupID, // Short, readable identifier
   ///             occurrence: Date.now,
   ///             details: details
   ///         )
   ///     }
   /// }
   /// ```
   ///
   /// The generated ID is a prefix of the SHA-256 hash of the error chain stripped of all parameters and messages,
   /// ensuring that only the structure of error types influences the grouping. The 6-character prefix provides
   /// enough uniqueness for practical error grouping while remaining readable in logs and analytics.
   ///
   /// - Parameter error: The error to generate a grouping ID for
   /// - Returns: A stable 6-character hexadecimal string that can be used to group similar errors
   public static func groupingID(for error: Error) -> String {
      let errorChainDescription = Self.errorChainDescription(for: error)

      // Split at first occurrence of "(" or ":" to remove specific parameters and user-friendly messages
      let descriptionWithoutDetails = errorChainDescription.components(separatedBy: CharacterSet(charactersIn: "(:")).first!

      #if canImport(CryptoKit)
      let digest = CryptoKit.SHA256.hash(data: Data(descriptionWithoutDetails.utf8))
      let fullHash = Data(digest).compactMap { String(format: "%02x", $0) }.joined()
      #else
      let digest = Crypto.SHA256.hash(data: Data(descriptionWithoutDetails.utf8))
      let fullHash = digest.compactMap { String(format: "%02x", $0) }.joined()
      #endif

      // Return first 6 characters for a shorter but still practically unique identifier
      return String(fullHash.prefix(6))
   }

   // MARK: - Error Mapping

   /// Registers a custom error mapper to extend ErrorKit's error mapping capabilities.
   ///
   /// This function allows you to add your own error mapper for specific frameworks, libraries, or custom error types.
   /// Registered mappers are queried in reverse order to ensure user-provided mappers takes precedence over built-in ones.
   ///
   /// # Usage
   /// Register error mappers during your app's initialization, typically in the App's initializer or main function:
   /// ```swift
   /// @main
   /// struct MyApp: App {
   ///     init() {
   ///         ErrorKit.registerMapper(MyDatabaseErrorMapper.self)
   ///         ErrorKit.registerMapper(AuthenticationErrorMapper.self)
   ///     }
   ///
   ///     var body: some Scene {
   ///         // ...
   ///     }
   /// }
   /// ```
   ///
   /// # Best Practices
   /// - Register mappers early in your app's lifecycle
   /// - Order matters: Register more specific mappers after general ones (last added is checked first)
   /// - Avoid redundant mappers for the same error types (as this may lead to confusion)
   ///
   /// # Example Mapper
   /// ```swift
   /// enum PaymentServiceErrorMapper: ErrorMapper {
   ///     static func userFriendlyMessage(for error: Error) -> String? {
   ///         switch error {
   ///         case let paymentError as PaymentService.Error:
   ///             switch paymentError {
   ///             case .cardDeclined:
   ///                 return String(localized: "Payment declined. Please try a different card.")
   ///             case .insufficientFunds:
   ///                 return String(localized: "Insufficient funds. Please add money to your account.")
   ///             case .expiredCard:
   ///                 return String(localized: "Card expired. Please update your payment method.")
   ///             default:
   ///                 return nil
   ///             }
   ///         default:
   ///             return nil
   ///         }
   ///     }
   /// }
   ///
   /// ErrorKit.registerMapper(PaymentServiceErrorMapper.self)
   /// ```
   ///
   /// - Parameter mapper: The error mapper type to register
   public static func registerMapper(_ mapper: ErrorMapper.Type) {
      self.errorMappersQueue.async(flags: .barrier) {
         self._errorMappers.append(mapper)
      }
   }

   /// A built-in sync mechanism to avoid concurrent access to ``errorMappers``.
   private static let errorMappersQueue = DispatchQueue(label: "ErrorKit.ErrorMappers", attributes: .concurrent)

   /// The collection of error mappers that ErrorKit uses to generate user-friendly messages.
   nonisolated(unsafe) private static var _errorMappers: [ErrorMapper.Type] = [
      FoundationErrorMapper.self,
      CoreDataErrorMapper.self,
      MapKitErrorMapper.self,
   ]

   /// Provides thread-safe read access to `_errorMappers` using a concurrent queue.
   private static var errorMappers: [ErrorMapper.Type] {
      self.errorMappersQueue.sync { self._errorMappers }
   }
}
