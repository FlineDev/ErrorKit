import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

public struct ThrowMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let code = node.argumentList.first?.expression, let message = node.argumentList.last?.expression else {
           fatalError("compiler bug: the macro does not have any arguments")
        }
        
        return "throw NSError.generic(code: \(code), message: \(message))"
    }
}
