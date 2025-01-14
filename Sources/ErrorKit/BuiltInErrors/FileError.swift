import Foundation

/// Represents errors that occur during file operations.
///
/// # Examples of Use
///
/// ## Handling File Retrieval
/// ```swift
/// struct DocumentManager {
///     func loadDocument(named name: String) throws(FileError) -> Document {
///         guard let fileURL = findFile(named: name) else {
///             throw .fileNotFound(fileName: name)
///         }
///         // Document loading logic
///     }
/// }
/// ```
///
/// ## Managing File Operations
/// ```swift
/// struct FileProcessor {
///     func processFile(at path: String) throws(FileError) {
///         guard canWrite(to: path) else {
///             throw .writeFailed(fileName: path)
///         }
///         // File processing logic
///     }
///
///     func readConfiguration() throws(FileError) -> Configuration {
///         guard let data = attemptFileRead() else {
///             throw .readFailed(fileName: "config.json")
///         }
///         // Configuration parsing logic
///     }
/// }
/// ```
public enum FileError: Throwable {
   /// The file could not be found.
   ///
   /// # Example
   /// ```swift
   /// struct AssetManager {
   ///     func loadImage(named name: String) throws(FileError) -> Image {
   ///         guard let imagePath = searchForImage(name) else {
   ///             throw .fileNotFound(fileName: name)
   ///         }
   ///         // Image loading logic
   ///     }
   /// }
   /// ```
   case fileNotFound(fileName: String)

   /// There was an issue reading the file.
   ///
   /// # Example
   /// ```swift
   /// struct LogReader {
   ///     func readLatestLog() throws(FileError) -> String {
   ///         guard let logContents = attemptFileRead() else {
   ///             throw .readFailed(fileName: "application.log")
   ///         }
   ///         return logContents
   ///     }
   /// }
   /// ```
   case readFailed(fileName: String)

   /// There was an issue writing to the file.
   ///
   /// # Example
   /// ```swift
   /// struct DataBackup {
   ///     func backup(data: Data) throws(FileError) {
   ///         guard canWriteToBackupLocation() else {
   ///             throw .writeFailed(fileName: "backup.dat")
   ///         }
   ///         // Backup writing logic
   ///     }
   /// }
   /// ```
   case writeFailed(fileName: String)

   /// Generic error message if the existing cases don't provide the required details.
   ///
   /// # Example
   /// ```swift
   /// struct FileIntegrityChecker {
   ///     func validateFile() throws(FileError) {
   ///         guard passes(integrityCheck) else {
   ///             throw .generic(userFriendlyMessage: "File integrity compromised")
   ///         }
   ///         // Validation logic
   ///     }
   /// }
   /// ```
   case generic(userFriendlyMessage: String)

   /// A user-friendly error message suitable for display to end users.
   public var userFriendlyMessage: String {
      switch self {
      case .fileNotFound(let fileName):
         return String(
            localized: "BuiltInErrors.FileError.fileNotFound",
            defaultValue: "The file \(fileName) could not be located. Please verify the file path and try again.",
            bundle: .module
         )
      case .readFailed(let fileName):
         return String(
            localized: "BuiltInErrors.FileError.readError",
            defaultValue: "An error occurred while attempting to read the file \(fileName). Please check file permissions and try again.",
            bundle: .module
         )
      case .writeFailed(let fileName):
         return String(
            localized: "BuiltInErrors.FileError.writeError",
            defaultValue: "Unable to write to the file \(fileName). Ensure you have the necessary permissions and try again.",
            bundle: .module
         )
      case .generic(let userFriendlyMessage):
         return userFriendlyMessage
      }
   }
}
