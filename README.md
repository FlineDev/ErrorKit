# ErrorKit

**ErrorKit** makes error handling in Swift more intuitive. It reduces boilerplate code while providing clearer insights. Helpful for users, fun for developers!

*TODO: Add a list of advantages of using ErrorKit over Swift’s native error handling types.*

---

## Why We Introduced the `Throwable` Protocol to Replace `Error`

### The Confusing `Error` API

Swift's `Error` protocol is simple – too simple. It has no requirements, but it offers one computed property, `localizedDescription`, which is often used to log errors or display messages to users.

Consider the following example where we provide a `localizedDescription` for an enum:

```swift
enum NetworkError: Error, CaseIterable {
   case noConnectionToServer
   case parsingFailed

   var localizedDescription: String {
      switch self {
      case .noConnectionToServer: "No connection to the server."
      case .parsingFailed: "Data parsing failed."
      }
   }
}
```

You might expect this to work seamlessly, but it doesn’t. If we randomly throw an error and print its `localizedDescription`, like in the following SwiftUI view:

```swift
struct ContentView: View {
   var body: some View {
      Button("Throw Random NetworkError") {
         do {
            throw NetworkError.allCases.randomElement()!
         } catch {
            print("Caught error with message: \(error.localizedDescription)")
         }
      }
   }
}
```

The console output will surprise you: 😱

```bash
Caught error with message: The operation couldn’t be completed. (ErrorKitDemo.NetworkError error 0.)
```

There’s no information about the specific error case. Not even the enum case name appears, let alone the custom message! Why? Because Swift’s `Error` protocol is bridged to `NSError`, which uses `domain`, `code`, and `userInfo` instead.

### The "Correct" Way: `LocalizedError`

The correct approach is to conform to `LocalizedError`, which defines the following optional properties:  

- `errorDescription: String?`
- `failureReason: String?`
- `recoverySuggestion: String?`
- `helpAnchor: String?`

However, since all of these properties are optional, you won’t get any compiler errors if you forget to implement them. Worse, only `errorDescription` affects `localizedDescription`. Fields like `failureReason` and `recoverySuggestion` are ignored, while `helpAnchor` is rarely used nowadays.

This makes `LocalizedError` both confusing and error-prone.

### The Solution: `Throwable`

To address these issues, **ErrorKit** introduces the `Throwable` protocol:

```swift
public protocol Throwable: LocalizedError {
   var userFriendlyMessage: String { get }
}
```

This protocol is simple and clear. It’s named `Throwable` to align with Swift’s `throw` keyword and follows Swift’s convention of using the `able` suffix (like `Codable` and `Identifiable`). Most importantly, it requires the `userFriendlyMessage` property, ensuring your errors behave exactly as expected.

Here’s how you use it:

```swift
enum NetworkError: Throwable {
   case noConnectionToServer
   case parsingFailed

   var userFriendlyMessage: String {
      switch self {
      case .noConnectionToServer: "Unable to connect to the server."
      case .parsingFailed: "Data parsing failed."
      }
   }
}
```

When you print `error.localizedDescription`, you'll get exactly the message you expect! 🥳

### Even Shorter Error Definitions

Not all apps are localized, and developers may not have time to provide localized descriptions immediately. To make error handling even simpler, `Throwable` allows you to define your error messages using raw values:

```swift
enum NetworkError: String, Throwable {
   case noConnectionToServer = "Unable to connect to the server."
   case parsingFailed = "Data parsing failed."
}
```

This approach eliminates boilerplate code while keeping the error definitions concise and descriptive.

### Summary

> Conform your custom error types to `Throwable` instead of `Error` or `LocalizedError`. The `Throwable` protocol requires only `userFriendlyMessage: String`, ensuring your error messages are exactly what you expect – no surprises.


## Enhanced Error Descriptions with `userFriendlyMessage(for:)`

ErrorKit goes beyond simplifying error handling — it enhances the clarity of error messages by providing improved, localized descriptions. With the `ErrorKit.userFriendlyMessage(for:)` function, developers can deliver clear, user-friendly error messages tailored to their audience.

### How It Works

The `userFriendlyMessage(for:)` function analyzes the provided `Error` and returns an enhanced, localized message. It draws on a community-maintained collection of descriptions to ensure the messages are accurate, helpful, and continuously evolving.

### Supported Error Domains

ErrorKit supports errors from various domains such as `Foundation`, `CoreData`, `MapKit`, and more. These domains are continuously updated, providing coverage for the most common error types in Swift development.

### Usage Example

Here’s how to use `userFriendlyMessage(for:)` to handle errors gracefully:

```swift
do {
    // Attempt a network request
    let url = URL(string: "https://example.com")!
    let _ = try Data(contentsOf: url)
} catch {
    // Print or show the enhanced error message to a user
    print(ErrorKit.userFriendlyMessage(for: error))
    // Example output: "You are not connected to the Internet. Please check your connection."
}
```

### Why Use `userFriendlyMessage(for:)`?

- **Localization**: Error messages are localized to ~40 languages to provide a better user experience.
- **Clarity**: Returns clear and concise error messages, avoiding cryptic system-generated descriptions.
- **Community Contributions**: The descriptions are regularly improved by the developer community. If you encounter a new or unexpected error, feel free to contribute by submitting a pull request.

### Contribution Welcome!

Found a bug or missing description? We welcome your contributions! Submit a pull request (PR), and we’ll gladly review and merge it to enhance the library further.

> **Note:** The enhanced error descriptions are constantly evolving, and we’re committed to making them as accurate and helpful as possible.

## Overloads of Common System Functions with Typed Throws

ErrorKit introduces typed-throws overloads for common system APIs like `FileManager` and `URLSession`, providing more granular error handling and improved code clarity. These overloads allow you to handle specific error scenarios with tailored responses, making your code more robust and easier to maintain.

To streamline discovery, ErrorKit uses the same API names prefixed with `throwable`. These functions throw specific errors that conform to `Throwable`, allowing for clear and informative error messages.

**Enhanced User-Friendly Error Messages:**

One of the key advantages of ErrorKit's typed throws is the improved `localizedDescription` property. This property provides user-friendly error messages that are tailored to the specific error type. This eliminates the need for manual error message construction and ensures a consistent and informative user experience.

**Example: Creating a Directory**

```swift
do {
  try FileManager.default.throwableCreateDirectory(at: URL(string: "file:///path/to/directory")!)
} catch {
   switch error {
   case FileManagerError.noWritePermission:
      // Request write permission from the user intead of showing error message
   default:
      // Common error cases have a more descriptive message
      showErrorDialog(error.localizedDescription)
   }
}
```

The code demonstrates how to handle errors for specific error cases with an improved UX rather than just showing an error message to the user, which can still be the fallback. And the error cases are easy to discover thanks to the typed enum error.

**Example: Handling network request errors**

```swift
do {
  let (data, response) = try await URLSession.shared.throwableData(from: URL(string: "https://api.example.com/data")!)
  // Process the data and response
} catch {
  // Error is of type `URLSessionError`
  print(error.localizedDescription)

  switch error {
  case .timeout, .requestTimeout, .tooManyRequests:
    // Automatically retry the request with a backoff strategy
  case .noNetwork:
    // Show an SF Symbol indicating the user is offline plus a retry button
  case .unauthorized:
    // Redirect the user to your login-flow (e.g. because token expired)
  default:
    // Fall back to showing error message
  }
}
```

Here, the code leverages the specific error types to implement various kinds of custom logic. This demonstrates the power of typed throws in providing fine-grained control over error handling.

### Summary

By utilizing these typed-throws overloads, you can write more robust and maintainable code. ErrorKit's enhanced user-friendly messages and ability to handle specific errors with code lead to a better developer and user experience. As the library continues to evolve, we encourage the community to contribute additional overloads and error types for common system APIs to further enhance its capabilities.
