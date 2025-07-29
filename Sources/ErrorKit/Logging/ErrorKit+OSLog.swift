#if canImport(OSLog)
import Foundation
import OSLog

import Foundation
import OSLog

extension ErrorKit {
   /// Returns log data from the unified logging system for a specified time period and minimum level.
   ///
   /// This function collects logs from your app and generates a string representation that can
   /// be attached to support emails or saved for diagnostic purposes. It provides the log data
   /// directly rather than creating a file, giving you flexibility in how you use the data.
   ///
   /// - Parameters:
   ///   - duration: How far back in time to collect logs.
   ///     For example, `.minutes(5)` collects logs from the last 5 minutes.
   ///   - minLevel: The minimum log level to include (default: .notice).
   ///     Higher levels include less but more important information:
   ///     - `.debug`: All logs (very verbose)
   ///     - `.info`: Informational logs and above
   ///     - `.notice`: Notable events (default)
   ///     - `.error`: Only errors and faults
   ///     - `.fault`: Only critical errors
   ///
   /// - Returns: Data object containing the log content as UTF-8 encoded text
   /// - Throws: Errors if log store access fails
   ///
   /// ## Example: Attach Logs to Support Email
   /// ```swift
   /// func sendSupportEmail() {
   ///     do {
   ///         // Get logs from the last 5 minutes
   ///         let logData = try ErrorKit.loggedData(
   ///             ofLast: .seconds(5),
   ///             minLevel: .notice
   ///         )
   ///
   ///         // Create and present mail composer
   ///         if MFMailComposeViewController.canSendMail() {
   ///             let mail = MFMailComposeViewController()
   ///             mail.setToRecipients(["support@yourapp.com"])
   ///             mail.setSubject("Support Request")
   ///             mail.setMessageBody("Please describe your issue here:", isHTML: false)
   ///
   ///             // Attach the log data
   ///             mail.addAttachmentData(
   ///                 logData,
   ///                 mimeType: "text/plain",
   ///                 fileName: "app_logs.txt"
   ///             )
   ///
   ///             present(mail, animated: true)
   ///         }
   ///     } catch {
   ///         // Handle log export error
   ///         showAlert(message: "Could not attach logs: \(error.localizedDescription)")
   ///     }
   /// }
   /// ```
   ///
   /// - See Also: ``exportLogFile(ofLast:minLevel:)`` for when you need a URL with the log content written to a text file
   @available(macOS 13, *)
   public static func loggedData(ofLast duration: Duration, minLevel: OSLogEntryLog.Level = .notice) throws -> Data {
      let logStore = try OSLogStore(scope: .currentProcessIdentifier)

      let fromDate = Date.now.advanced(by: -duration.timeInterval)
      let fromDatePosition = logStore.position(date: fromDate)

      let levelPredicate = NSPredicate(format: "level >= %d", minLevel.rawValue)

      let entries = try logStore.getEntries(with: [.reverse], at: fromDatePosition, matching: levelPredicate)
      let logMessages = entries.map(\.composedMessage).joined(separator: "\n")
      return Data(logMessages.utf8)
   }

   /// Exports logs from the unified logging system to a file for a specified time period and minimum level.
   ///
   /// This convenience function builds on ``loggedData(ofLast:minLevel:)`` by writing the log data
   /// to a temporary file. This is useful when working with APIs that require a file URL rather than Data.
   ///
   /// - Parameters:
   ///   - duration: How far back in time to collect logs
   ///   - minLevel: The minimum log level to include (default: .notice)
   ///
   /// - Returns: URL to the temporary file containing the exported logs
   /// - Throws: Errors if log store access fails or if writing to the file fails
   ///
   /// - See Also: ``loggedData(ofLast:minLevel:)`` for when you need the log content as Data directly
   @available(macOS 13, *)
   public static func exportLogFile(ofLast duration: Duration, minLevel: OSLogEntryLog.Level = .notice) throws -> URL {
      let logData = try loggedData(ofLast: duration, minLevel: minLevel)

      let fileName = "logs_\(Date.now.formatted(.iso8601)).txt"
      let fileURL = FileManager.default.temporaryDirectory.appending(path: fileName)

      try logData.write(to: fileURL)
      return fileURL
   }

   /// Creates a mail attachment containing log data from the unified logging system.
   ///
   /// This convenience function builds on the logging functionality to create a ready-to-use
   /// mail attachment for including logs in support emails or bug reports.
   ///
   /// - Parameters:
   ///   - duration: How far back in time to collect logs.
   ///     For example, `.minutes(5)` collects logs from the last 5 minutes.
   ///   - minLevel: The minimum log level to include (default: .notice).
   ///     Higher levels include less but more important information:
   ///     - `.debug`: All logs (very verbose)
   ///     - `.info`: Informational logs and above
   ///     - `.notice`: Notable events (default)
   ///     - `.error`: Only errors and faults
   ///     - `.fault`: Only critical errors
   ///   - filename: Optional custom filename for the log attachment (default: "app_logs_[timestamp].txt")
   ///
   /// - Returns: A `MailAttachment` ready to be used with the mail composer
   /// - Throws: Errors if log store access fails
   ///
   /// ## Example: Attach Logs to Support Email
   /// ```swift
   /// Button("Report Problem") {
   ///     do {
   ///         // Get logs from the last hour as a mail attachment
   ///         let logAttachment = try ErrorKit.logAttachment(
   ///             ofLast: .minutes(60),
   ///             minLevel: .notice
   ///         )
   ///
   ///         showMailComposer = true
   ///     } catch {
   ///         errorMessage = "Could not prepare logs: \(error.localizedDescription)"
   ///         showError = true
   ///     }
   /// }
   /// .mailComposer(
   ///     isPresented: $showMailComposer,
   ///     recipients: ["support@yourapp.com"],
   ///     subject: "Bug Report",
   ///     messageBody: "I encountered the following issue:",
   ///     attachments: [logAttachment]
   /// )
   /// ```
   @available(macOS 13, *)
   public static func logAttachment(
      ofLast duration: Duration,
      minLevel: OSLogEntryLog.Level = .notice,
      filename: String? = nil
   ) throws -> MailAttachment {
      let logData = try loggedData(ofLast: duration, minLevel: minLevel)

      let attachmentFilename = filename ?? "app_logs_\(Date.now.formatted(.iso8601)).txt"

      return MailAttachment(
         data: logData,
         mimeType: "text/plain",
         filename: attachmentFilename
      )
   }
}

@available(macOS 13, *)
extension Duration {
   /// Returns the duration as a `TimeInterval`.
   ///
   /// This can be useful for interfacing with APIs that require `TimeInterval` (which is measured in seconds), allowing you to convert a `Duration` directly to the needed format.
   ///
   /// Example:
   /// ```swift
   /// let duration = Duration.hours(2)
   /// let timeInterval = duration.timeInterval // Converts to TimeInterval for compatibility
   /// ```
   ///
   /// - Returns: The duration as a `TimeInterval`, which represents the duration in seconds.
   public var timeInterval: TimeInterval {
      TimeInterval(self.components.seconds) + (TimeInterval(self.components.attoseconds) / 1_000_000_000_000_000_000)
   }

   /// Constructs a `Duration` given a number of minutes represented as a `BinaryInteger`.
   ///
   /// This is helpful for precise time measurements, such as cooking timers, short breaks, or meeting durations.
   ///
   /// Example:
   /// ```swift
   /// let fifteenMinutesDuration = Duration.minutes(15) // Creates a Duration of 15 minutes
   /// ```
   ///
   /// - Parameter minutes: The number of minutes.
   /// - Returns: A `Duration` representing the given number of minutes.
   public static func minutes<T: BinaryInteger>(_ minutes: T) -> Duration {
      self.seconds(minutes * 60)
   }

   /// Constructs a `Duration` given a number of hours represented as a `BinaryInteger`.
   ///
   /// Can be used to schedule events or tasks that are several hours long.
   ///
   /// Example:
   /// ```swift
   /// let eightHoursDuration = Duration.hours(8) // Creates a Duration of 8 hours
   /// ```
   ///
   /// - Parameter hours: The number of hours.
   /// - Returns: A `Duration` representing the given number of hours.
   public static func hours<T: BinaryInteger>(_ hours: T) -> Duration {
      self.minutes(hours * 60)
   }
}
#endif
