/// A protocol built for typed throws that enables automatic error wrapping for nested error hierarchies through a `caught` case.
/// This simplifies error handling in modular applications where errors need to be propagated up through multiple layers.
///
/// # Overview
/// When working with nested error types in a modular application, you often need to wrap errors from lower-level
/// modules into higher-level error types. This protocol provides a convenient way to handle such error wrapping
/// without manually defining wrapper cases for each possible error type.
///
/// # Example
/// Consider an app with profile management that uses both database and file operations:
/// ```swift
/// // Lower-level error types
/// enum DatabaseError: Throwable, Catching {
///     case connectionFailed
///     case recordNotFound(entity: String, identifier: String?)
///     case caught(Error)  // Wraps any other database-related errors
/// }
///
/// enum FileError: Throwable, Catching {
///     case notFound(path: String)
///     case accessDenied(path: String)
///     case caught(Error)  // Wraps any other file system errors
/// }
///
/// // Higher-level error type
/// enum ProfileError: Throwable, Catching {
///     case validationFailed(field: String)
///     case caught(Error)  // Automatically wraps both DatabaseError and FileError
/// }
///
/// struct ProfileRepository {
///     func loadProfile(id: String) throws(ProfileError) {
///         // Explicit error for validation
///         guard id.isValidFormat else {
///             throw ProfileError.validationFailed(field: "id")
///         }
///
///         // Automatically wrap any database or file errors
///         let userData = try ProfileError.catch {
///             let user = try database.loadUser(id)
///             let settings = try fileSystem.readUserSettings(user.settingsPath)
///             return UserProfile(user: user, settings: settings)
///         }
///
///         // Use the loaded data
///         self.currentProfile = userData
///     }
/// }
/// ```
///
/// Without Catching protocol, you would need explicit cases and manual mapping:
/// ```swift
/// enum ProfileError: Throwable {
///     case validationFailed(field: String)
///     case databaseError(DatabaseError)    // Extra case needed
///     case fileError(FileError)           // Extra case needed
/// }
///
/// struct ProfileRepository {
///     func loadProfile(id: String) throws(ProfileError) {
///         guard id.isValidFormat else {
///             throw ProfileError.validationFailed(field: "id")
///         }
///
///         // Manual error mapping needed for each error type
///         do {
///             let user = try database.loadUser(id)
///             // Nested try-catch needed
///             do {
///                 let settings = try fileSystem.readUserSettings(user.settingsPath)
///                 self.currentProfile = UserProfile(user: user, settings: settings)
///             } catch let error as FileError {
///                 throw .fileError(error)
///             }
///         } catch let error as DatabaseError {
///             throw .databaseError(error)
///         }
///     }
/// }
/// ```
///
/// # Benefits
/// - Simplified error type definitions with a single catch-all case
/// - Automatic wrapping of any error type without manual case mapping
/// - Maintained type safety through typed throws
/// - Clean, readable error handling code
/// - Easy propagation of errors through multiple layers
/// - Transparent handling of return values from wrapped operations
public protocol Catching {
   /// Creates an instance of this error type that wraps another error.
   /// Used internally by the ``catch(_:)`` function to automatically wrap any thrown errors.
   ///
   /// - Parameter error: The error to be wrapped in this error type.
   static func caught(_ error: Error) -> Self
}

extension Catching {
   /// Executes a throwing operation and automatically wraps any thrown errors into this error type's `caught` case,
   /// while passing through the operation's return value on success. Great for functions using typed throws.
   ///
   /// # Overview
   /// This function provides a convenient way to:
   /// - Execute throwing operations
   /// - Automatically wrap any errors into the current error type
   /// - Pass through return values from the wrapped code
   /// - Maintain type safety with typed throws
   ///
   /// # Example
   /// ```swift
   /// struct ProfileRepository {
   ///     func loadProfile(id: String) throws(ProfileError) {
   ///         // Regular error throwing for validation
   ///         guard id.isValidFormat else {
   ///             throw ProfileError.validationFailed(field: "id")
   ///         }
   ///
   ///         // Automatically wrap any database or file errors while handling return value
   ///         let userData = try ProfileError.catch {
   ///             let user = try database.loadUser(id)
   ///             let settings = try fileSystem.readUserSettings(user.settingsPath)
   ///             return UserProfile(user: user, settings: settings)
   ///         }
   ///
   ///         // Use the loaded data
   ///         self.currentProfile = userData
   ///     }
   /// }
   /// ```
   ///
   /// - Parameter operation: The throwing operation to execute.
   /// - Returns: The value returned by the operation if successful.
   /// - Throws: An instance of `Self` with the original error wrapped in the `caught` case.
   public static func `catch`<ReturnType>(
      _ operation: () throws -> ReturnType
   ) throws(Self) -> ReturnType {
      do {
         return try operation()
      } catch let error as Self {
         throw error
      } catch {
         throw Self.caught(error)
      }
   }

   /// Executes an async throwing operation and automatically wraps any thrown errors into this error type's `caught` case,
   /// while passing through the operation's return value on success. Great for functions using typed throws.
   ///
   /// # Overview
   /// This function provides a convenient way to:
   /// - Execute async throwing operations
   /// - Automatically wrap any errors into the current error type
   /// - Pass through return values from the wrapped code
   /// - Maintain type safety with typed throws
   ///
   /// # Example
   /// ```swift
   /// struct ProfileRepository {
   ///     func loadProfile(id: String) throws(ProfileError) {
   ///         // Regular error throwing for validation
   ///         guard id.isValidFormat else {
   ///             throw ProfileError.validationFailed(field: "id")
   ///         }
   ///
   ///         // Automatically wrap any database or file errors while handling return value
   ///         let userData = try await ProfileError.catch {
   ///             let user = try await database.loadUser(id)
   ///             let settings = try await fileSystem.readUserSettings(user.settingsPath)
   ///             return UserProfile(user: user, settings: settings)
   ///         }
   ///
   ///         // Use the loaded data
   ///         self.currentProfile = userData
   ///     }
   /// }
   /// ```
   ///
   /// - Parameter operation: The async throwing operation to execute.
   /// - Returns: The value returned by the operation if successful.
   /// - Throws: An instance of `Self` with the original error wrapped in the `caught` case.
   public static func `catch`<ReturnType>(
      _ operation: () async throws -> ReturnType
   ) async throws(Self) -> ReturnType {
      do {
         return try await operation()
      } catch let error as Self {
         throw error
      } catch {
         throw Self.caught(error)
      }
   }
}
