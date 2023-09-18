import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

public struct RichErrorMacro: ExpressionMacro {
   public static func expansion(
      of node: some FreestandingMacroExpansionSyntax,
      in context: some MacroExpansionContext
   ) -> ExprSyntax {
      guard let code = node.argumentList.first?.expression, let message = node.argumentList.last?.expression else {
         fatalError("compiler bug: the macro does not have any arguments")
      }

      // build a unique identifier for the error based on type name, function name, and error message

      return "NSError.generic(code: \(code), message: \(message))"
   }
}

@main
struct ErrorKitPlugin: CompilerPlugin {
   let providingMacros: [Macro.Type] = [
      RichErrorMacro.self,
      ThrowsToResultMacro.self,
      ThrowMacro.self,
   ]
}
