# Typed Throws and Error Nesting

Making Swift 6's typed throws practical with seamless error propagation across layers.

@Metadata {
   @PageImage(purpose: icon, source: "ErrorKit")
   @PageImage(purpose: card, source: "TypedThrowsAndNesting")
}

## Highlights

Swift 6 introduces typed throws (`throws(ErrorType)`) for stronger type safety in error handling. ErrorKit makes this powerful feature practical by solving the challenge of error propagation across layers with the `Catching` protocol.

### Understanding Typed Throws

Typed throws let you declare exactly which error types a function can throw:

```swift
func processFile() throws(FileError) {
    // This function can only throw FileError
}
```

This enables compile-time verification of error handling:

```swift
do {
    try processFile()
} catch FileError.fileNotFound {
    // Handle specific case
} catch FileError.readFailed {
    // Handle another specific case
}
// No need for a catch-all since all possibilities are covered
```

### System Function Overloads

ErrorKit provides typed-throws overloads for common system APIs. To streamline discovery, these overloads use the same API names prefixed with "throwable":

```swift
// Standard system API
try fileManager.createDirectory(at: url)

// ErrorKit typed overload - same name with "throwable" prefix
try fileManager.throwableCreateDirectory(at: url)
```

The overloaded versions:
- Return the same results as the original functions
- Throw specific error types with detailed information
- Provide better error messages for common failures

Available overloads include:

#### FileManager Operations
```swift
// Creating directories
try FileManager.default.throwableCreateDirectory(at: url)

// Removing items
try FileManager.default.throwableRemoveItem(at: url)

// Copying files
try FileManager.default.throwableCopyItem(at: sourceURL, to: destinationURL)

// Moving files
try FileManager.default.throwableMoveItem(at: sourceURL, to: destinationURL)
```

#### URLSession Operations
```swift
// Data tasks
let (data, response) = try await URLSession.shared.throwableData(from: url)

// Handling HTTP status codes
try URLSession.shared.handleHTTPStatusCode(statusCode, data: data)
```

These typed overloads provide a more granular approach to error handling, allowing for precise error handling and improved user experience.

### Enhanced User Experience with Typed Throws

Using typed throws allows developers to implement smarter error handling with specific responses to different error types:

```swift
do {
  let (data, response) = try await URLSession.shared.throwableData(from: URL(string: "https://api.example.com/data")!)
  // Process the data and response
} catch {
  // Error is of type `URLSessionError`
  switch error {
  case .timeout, .requestTimeout, .tooManyRequests:
    // Automatically retry the request with a backoff strategy
    retryWithExponentialBackoff()
    
  case .noNetwork:
    // Show an SF Symbol indicating the user is offline plus a retry button
    showOfflineView()
    
  case .unauthorized:
    // Redirect the user to your login-flow (e.g. because token expired)
    startAuthenticationFlow()
    
  default:
    // Fall back to showing error message
    showErrorAlert(message: error.localizedDescription)
  }
}
```

This specific error handling enables you to:
- Implement automatic retry strategies for transient errors
- Show UI appropriate to the specific error condition
- Trigger authentication flows for permission issues
- Provide a better overall user experience than generic error handling

### The Problem: Error Propagation

While typed throws improves type safety, it creates a challenge when propagating errors through multiple layers of an application. Without ErrorKit, you'd need to manually wrap errors at each layer:

```swift
enum ProfileError: Error {
    case validationFailed(field: String)
    case databaseError(DatabaseError)    // Wrapper case needed for database errors
    case networkError(NetworkError)      // Another wrapper for network errors

    var errorDescription: String { /* ... */ }
}

func loadProfile(id: String) throws(ProfileError) {
    // Regular error throwing for validation
    guard id.isValidFormat else {
        throw ProfileError.validationFailed(field: "id")
    }

    // Manually mapping nested errors
    do {
        let user = try database.loadUser(id)
        do {
            let settings = try fileSystem.readUserSettings(user.settingsPath)
            return UserProfile(user: user, settings: settings)
        } catch let error as NetworkError {
            throw ProfileError.networkError(error) // Manual wrapping
        }
    } catch let error as DatabaseError {
        throw ProfileError.databaseError(error) // Manual wrapping
    }
}
```

This approach requires:
1. Creating explicit wrapper cases for each possible error type
2. Writing repetitive do-catch blocks for manual error conversion
3. Maintaining this wrapping code as your error types evolve

### The Solution: Catching Protocol

ErrorKit's `Catching` protocol provides a clean solution:

```swift
enum ProfileError: Throwable, Catching {
    case validationFailed(field: String)
    case caught(Error)  // Single case handles all nested errors
    
    var userFriendlyMessage: String { /* ... */ }
}

func loadProfile(id: String) throws(ProfileError) {
    // Regular error throwing for validation
    guard id.isValidFormat else {
        throw ProfileError.validationFailed(field: "id")
    }
    
    // Automatically wrap any database or file errors
    let userData = try ProfileError.catch {
        let user = try database.loadUser(id)
        let settings = try fileSystem.readUserSettings(user.settingsPath)
        return UserProfile(user: user, settings: settings)
    }
    
    return userData
}
```

The `catch` function automatically wraps any errors thrown in its closure into the `caught` case, preserving both type safety and the error's original information.

### Best Practices for Using Catching

To get the most out of the `Catching` protocol, follow these best practices:

#### 1. When to Add Catching

Add `Catching` conformance when:
- Your error type might need to wrap errors from lower-level modules
- You're using typed throws and calling functions that throw different error types
- You want to create a hierarchy of errors for better organization

You'll know you need `Catching` when you see yourself writing error wrapper cases like:
```swift
enum MyError: Error {
    case specificError
    case otherModuleError(OtherError) // If you're writing wrapper cases, you need Catching
}
```

#### 2. Error Hierarchy Structure

Keep your error hierarchies shallow when possible:
- Aim for 2-3 levels at most (e.g., AppError → ModuleError → SystemError)
- Use specific error cases for known errors, and `caught` for others
- Consider organizing by module or feature rather than error type

#### 3. Preserve User-Friendly Messages

When implementing `userFriendlyMessage` for a `Catching` type:

```swift
var userFriendlyMessage: String {
    switch self {
    case .specificError:
        return "A specific error occurred."
    case .caught(let error):
        // Use ErrorKit's enhanced messages for wrapped errors
        return ErrorKit.userFriendlyMessage(for: error)
    }
}
```

This ensures that user-friendly messages propagate correctly through the error chain.

#### 4. Use with Built-in Error Types

All of ErrorKit's built-in error types already conform to `Catching`, so you can easily wrap system errors:

```swift
func saveUserData() throws(DatabaseError) {
    // Automatically wraps SQLite errors, file system errors, etc.
    try DatabaseError.catch {
        try database.beginTransaction()
        try database.execute(query)
        try database.commit()
    }
}
```

### Working with Error Chain Debugging

For complete visibility into your error chains, ErrorKit provides powerful debugging tools that work perfectly with `Catching`. These tools are covered in detail in the [Error Chain Debugging](Error-Chain-Debugging) documentation. 

When using typed throws with the `Catching` protocol, you'll benefit greatly from these debugging capabilities, as they allow you to:

- Visualize the complete error chain hierarchy
- Track errors through different application layers
- Identify patterns in error propagation
- Prioritize which errors to fix first

Be sure to explore the error chain debugging features to get the full benefit of ErrorKit's typed throws support.

## Topics

### Essentials

- ``Catching``
- ``Catching/catch(_:)-8kmn1``
- ``Catching/catch(_:)-63mkk``
- ``Catching/catch(isolation:_:)``

### System Overloads

- ``FileManager/throwableCreateDirectory(at:withIntermediateDirectories:attributes:)``
- ``FileManager/throwableRemoveItem(at:)``
- ``URLSession/throwableData(for:)``
- ``URLSession/throwableData(from:)``
- ``URLSession/handleHTTPStatusCode(_:data:)``

### Continue Reading

- <doc:Error-Chain-Debugging>
