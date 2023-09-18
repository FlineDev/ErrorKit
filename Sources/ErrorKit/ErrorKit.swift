import Foundation

@freestanding(expression)
public macro RichError(code: Int, message: String) -> NSError = #externalMacro(module: "ErrorKitMacros", type: "RichErrorMacro")

@attached(peer, names: suffixed(Error))
public macro ThrowsToResult() = #externalMacro(module: "ErrorKitMacros", type: "ThrowsToResultMacro")

@freestanding(expression)
public macro emit(code: Int, message: String) -> NSError = #externalMacro(module: "ErrorKitMacros", type: "ThrowMacro")

