import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

final class EmitStatementCollector: SyntaxVisitor {
    var nodes: [MacroExpansionExprSyntax] = []
    
    override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
        nodes.append(node)
        return .skipChildren
    }
}

public struct ThrowsToResultMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        /*
        MacroExpansionExprSyntax
        │       │ │     │     ├─pound: pound
        │       │ │     │     ├─macroName: identifier("emit")
        │       │ │     │     ├─leftParen: leftParen
        │       │ │     │     ├─arguments: LabeledExprListSyntax
        │       │ │     │     │ ├─[0]: LabeledExprSyntax
        │       │ │     │     │ │ ├─label: identifier("code")
        │       │ │     │     │ │ ├─colon: colon
        │       │ │     │     │ │ ├─expression: IntegerLiteralExprSyntax
        │       │ │     │     │ │ │ ╰─literal: integerLiteral("21693")
        │       │ │     │     │ │ ╰─trailingComma: comma
        │       │ │     │     │ ╰─[1]: LabeledExprSyntax
        │       │ │     │     │   ├─label: identifier("message")
        │       │ │     │     │   ├─colon: colon
        │       │ │     │     │   ╰─expression: StringLiteralExprSyntax
        │       │ │     │     │     ├─openingQuote: stringQuote
        │       │ │     │     │     ├─segments: StringLiteralSegmentListSyntax
        │       │ │     │     │     │ ├─[0]: StringSegmentSyntax
        │       │ │     │     │     │ │ ╰─content: stringSegment("No movies found matching the genre \'")
        │       │ │     │     │     │ ├─[1]: ExpressionSegmentSyntax
        │       │ │     │     │     │ │ ├─backslash: backslash
        │       │ │     │     │     │ │ ├─leftParen: leftParen
        │       │ │     │     │     │ │ ├─expressions: LabeledExprListSyntax
        │       │ │     │     │     │ │ │ ╰─[0]: LabeledExprSyntax
        │       │ │     │     │     │ │ │   ╰─expression: DeclReferenceExprSyntax
        │       │ │     │     │     │ │ │     ╰─baseName: identifier("genre")
        │       │ │     │     │     │ │ ╰─rightParen: rightParen
        │       │ │     │     │     │ ╰─[2]: StringSegmentSyntax
        │       │ │     │     │     │   ╰─content: stringSegment("\'.")
        │       │ │     │     │     ╰─closingQuote: stringQuote
        │       │ │     │     ├─rightParen: rightParen
        │       │ │     │     ╰─additionalTrailingClosures: MultipleTrailingClosureElementListSyntax
        */
        
        let collector = EmitStatementCollector(viewMode: .all)
        collector.walk(declaration)
        let builders = collector.nodes
            .filter { $0.macroName.tokenKind == .identifier("RichError") }
            .compactMap {
                guard let code: String = $0.arguments.first?.expression.as(IntegerLiteralExprSyntax.self)?.literal.trimmed.text,
                      let message: String = $0.arguments.last?.expression.as(StringLiteralExprSyntax.self)?.segments.first?.as(StringSegmentSyntax.self)?.content.trimmed.text
                else {
                    return Optional<(String, String)>.none
                }
                
                return (code, message)
            }
            //.map { "case errorCode\($0.0) = \"\($0.1)\"" }
            .map { "public static func errorCode\($0.0)(message: String) -> Self { Self(code: ErrorCode(rawValue: \($0.0))!, message: message) }" }
            .joined(separator: "\n")
        
        let codeCases = collector.nodes
            .filter { $0.macroName.tokenKind == .identifier("RichError") }
            .compactMap { $0.arguments.first?.expression.as(IntegerLiteralExprSyntax.self)?.literal.trimmed.text }
            .map { "case errorCode\($0) = \($0)" }
            .joined(separator: "\n")

        return [
            """
            public struct \(raw: declaration.as(StructDeclSyntax.self)!.name.trimmed.text)Error: Error {
                public enum ErrorCode: Int {
                    \(raw: codeCases)
                }
            
                public let code: ErrorCode
                public let message: String
            
                \(raw: builders)
            }
            """
        ]
    }
}

/*
StructDeclSyntax
├─ attributes: AttributeListSyntax
│
╰─ [0]: AttributeSyntax
│   ├─atSign: atSign
│   ╰─attributeName: IdentifierTypeSyntax
│     ╰─name: identifier("ThrowsToResult")
├─modifiers: DeclModifierListSyntax
├─structKeyword: keyword(SwiftSyntax.Keyword.struct)
├─name: identifier("Movie")
├─inheritanceClause: InheritanceClauseSyntax
│ ├─colon: colon
│ ╰─inheritedTypes: InheritedTypeListSyntax
│   ╰─[0]: InheritedTypeSyntax
│     ╰─type: IdentifierTypeSyntax
│       ╰─name: identifier("Equatable")
╰─memberBlock: MemberBlockSyntax
├─leftBrace: leftBrace
├─members: MemberBlockItemListSyntax
│ ├─[0]: MemberBlockItemSyntax
│ │ ╰─decl: VariableDeclSyntax
│ │   ├─attributes: AttributeListSyntax
│ │   ├─modifiers: DeclModifierListSyntax
│ │   ├─bindingSpecifier: keyword(SwiftSyntax.Keyword.let)
│ │   ╰─bindings: PatternBindingListSyntax
│ │     ╰─[0]: PatternBindingSyntax
│ │       ├─pattern: IdentifierPatternSyntax
│ │       │ ╰─identifier: identifier("title")
│ │       ╰─typeAnnotation: TypeAnnotationSyntax
│ │         ├─colon: colon
│ │         ╰─type: IdentifierTypeSyntax
│ │           ╰─name: identifier("String")
│ ├─[1]: MemberBlockItemSyntax
│ │ ╰─decl: VariableDeclSyntax
│ │   ├─attributes: AttributeListSyntax
│ │   ├─modifiers: DeclModifierListSyntax
│ │   ├─bindingSpecifier: keyword(SwiftSyntax.Keyword.let)
│ │   ╰─bindings: PatternBindingListSyntax
│ │     ╰─[0]: PatternBindingSyntax
│ │       ├─pattern: IdentifierPatternSyntax
│ │       │ ╰─identifier: identifier("releaseYear")
│ │       ╰─typeAnnotation: TypeAnnotationSyntax
│ │         ├─colon: colon
│ │         ╰─type: IdentifierTypeSyntax
│ │           ╰─name: identifier("Int")
│ ├─[2]: MemberBlockItemSyntax
│ │ ╰─decl: EnumDeclSyntax
│ │   ├─attributes: AttributeListSyntax
│ │   ├─modifiers: DeclModifierListSyntax
│ │   ├─enumKeyword: keyword(SwiftSyntax.Keyword.enum)
│ │   ├─name: identifier("Genre")
│ │   ╰─memberBlock: MemberBlockSyntax
│ │     ├─leftBrace: leftBrace
│ │     ├─members: MemberBlockItemListSyntax
│ │     │ ╰─[0]: MemberBlockItemSyntax
│ │     │   ╰─decl: EnumCaseDeclSyntax
│ │     │     ├─attributes: AttributeListSyntax
│ │     │     ├─modifiers: DeclModifierListSyntax
│ │     │     ├─caseKeyword: keyword(SwiftSyntax.Keyword.case)
│ │     │     ╰─elements: EnumCaseElementListSyntax
│ │     │       ├─[0]: EnumCaseElementSyntax
│ │     │       │ ├─name: identifier("action")
│ │     │       │ ╰─trailingComma: comma
│ │     │       ├─[1]: EnumCaseElementSyntax
│ │     │       │ ├─name: identifier("anime")
│ │     │       │ ╰─trailingComma: comma
│ │     │       ├─[2]: EnumCaseElementSyntax
│ │     │       │ ├─name: identifier("bollywood")
│ │     │       │ ╰─trailingComma: comma
│ │     │       ├─[3]: EnumCaseElementSyntax
│ │     │       │ ├─name: identifier("comedy")
│ │     │       │ ╰─trailingComma: comma
│ │     │       ╰─[4]: EnumCaseElementSyntax
│ │     │         ╰─name: identifier("drama")
│ │     ╰─rightBrace: rightBrace
│ ╰─[3]: MemberBlockItemSyntax
│   ╰─decl: FunctionDeclSyntax
│     ├─attributes: AttributeListSyntax
│     ├─modifiers: DeclModifierListSyntax
│     │ ╰─[0]: DeclModifierSyntax
│     │   ╰─name: keyword(SwiftSyntax.Keyword.static)
│     ├─funcKeyword: keyword(SwiftSyntax.Keyword.func)
│     ├─name: identifier("randomMovies")
│     ├─signature: FunctionSignatureSyntax
│     │ ├─parameterClause: FunctionParameterClauseSyntax
│     │ │ ├─leftParen: leftParen
│     │ │ ├─parameters: FunctionParameterListSyntax
│     │ │ │ ├─[0]: FunctionParameterSyntax
│     │ │ │ │ ├─attributes: AttributeListSyntax
│     │ │ │ │ ├─modifiers: DeclModifierListSyntax
│     │ │ │ │ ├─firstName: identifier("genre")
│     │ │ │ │ ├─colon: colon
│     │ │ │ │ ├─type: IdentifierTypeSyntax
│     │ │ │ │ │ ╰─name: identifier("Genre")
│     │ │ │ │ ╰─trailingComma: comma
│     │ │ │ ╰─[1]: FunctionParameterSyntax
│     │ │ │   ├─attributes: AttributeListSyntax
│     │ │ │   ├─modifiers: DeclModifierListSyntax
│     │ │ │   ├─firstName: identifier("count")
│     │ │ │   ├─colon: colon
│     │ │ │   ╰─type: IdentifierTypeSyntax
│     │ │ │     ╰─name: identifier("Int")
│     │ │ ╰─rightParen: rightParen
│     │ ├─effectSpecifiers: FunctionEffectSpecifiersSyntax
│     │ │ ╰─throwsSpecifier: keyword(SwiftSyntax.Keyword.throws)
│     │ ╰─returnClause: ReturnClauseSyntax
│     │   ├─arrow: arrow
│     │   ╰─type: ArrayTypeSyntax
│     │     ├─leftSquare: leftSquare
│     │     ├─element: IdentifierTypeSyntax
│     │     │ ╰─name: identifier("Movie")
│     │     ╰─rightSquare: rightSquare
│     ╰─body: CodeBlockSyntax
│       ├─leftBrace: leftBrace
│       ├─statements: CodeBlockItemListSyntax
│       │ ├─[0]: CodeBlockItemSyntax
│       │ │ ╰─item: VariableDeclSyntax
│       │ │   ├─attributes: AttributeListSyntax
│       │ │   ├─modifiers: DeclModifierListSyntax
│       │ │   ├─bindingSpecifier: keyword(SwiftSyntax.Keyword.var)
│       │ │   ╰─bindings: PatternBindingListSyntax
│       │ │     ╰─[0]: PatternBindingSyntax
│       │ │       ├─pattern: IdentifierPatternSyntax
│       │ │       │ ╰─identifier: identifier("movies")
│       │ │       ╰─initializer: InitializerClauseSyntax
│       │ │         ├─equal: equal
│       │ │         ╰─value: TryExprSyntax
│       │ │           ├─tryKeyword: keyword(SwiftSyntax.Keyword.try)
│       │ │           ╰─expression: FunctionCallExprSyntax
│       │ │             ├─calledExpression: MemberAccessExprSyntax
│       │ │             │ ├─base: DeclReferenceExprSyntax
│       │ │             │ │ ╰─baseName: identifier("Database")
│       │ │             │ ├─period: period
│       │ │             │ ╰─declName: DeclReferenceExprSyntax
│       │ │             │   ╰─baseName: identifier("loadMovies")
│       │ │             ├─leftParen: leftParen
│       │ │             ├─arguments: LabeledExprListSyntax
│       │ │             │ ╰─[0]: LabeledExprSyntax
│       │ │             │   ├─label: identifier("byGenre")
│       │ │             │   ├─colon: colon
│       │ │             │   ╰─expression: DeclReferenceExprSyntax
│       │ │             │     ╰─baseName: identifier("genre")
│       │ │             ├─rightParen: rightParen
│       │ │             ╰─additionalTrailingClosures: MultipleTrailingClosureElementListSyntax
│       │ ├─[1]: CodeBlockItemSyntax
│       │ │ ╰─item: GuardStmtSyntax
│       │ │   ├─guardKeyword: keyword(SwiftSyntax.Keyword.guard)
│       │ │   ├─conditions: ConditionElementListSyntax
│       │ │   │ ╰─[0]: ConditionElementSyntax
│       │ │   │   ╰─condition: PrefixOperatorExprSyntax
│       │ │   │     ├─operator: prefixOperator("!")
│       │ │   │     ╰─expression: MemberAccessExprSyntax
│       │ │   │       ├─base: DeclReferenceExprSyntax
│       │ │   │       │ ╰─baseName: identifier("movies")
│       │ │   │       ├─period: period
│       │ │   │       ╰─declName: DeclReferenceExprSyntax
│       │ │   │         ╰─baseName: identifier("isEmpty")
│       │ │   ├─elseKeyword: keyword(SwiftSyntax.Keyword.else)
│       │ │   ╰─body: CodeBlockSyntax
│       │ │     ├─leftBrace: leftBrace
│       │ │     ├─statements: CodeBlockItemListSyntax
│       │ │     │ ╰─[0]: CodeBlockItemSyntax
│       │ │     │   ╰─item: ThrowStmtSyntax
│       │ │     │     ├─throwKeyword: keyword(SwiftSyntax.Keyword.throw)
│       │ │     │     ╰─expression: MacroExpansionExprSyntax
│       │ │     │       ├─pound: pound
│       │ │     │       ├─macroName: identifier("RichError")
│       │ │     │       ├─leftParen: leftParen
│       │ │     │       ├─arguments: LabeledExprListSyntax
│       │ │     │       │ ├─[0]: LabeledExprSyntax
│       │ │     │       │ │ ├─label: identifier("code")
│       │ │     │       │ │ ├─colon: colon
│       │ │     │       │ │ ├─expression: IntegerLiteralExprSyntax
│       │ │     │       │ │ │ ╰─literal: integerLiteral("21693")
│       │ │     │       │ │ ╰─trailingComma: comma
│       │ │     │       │ ╰─[1]: LabeledExprSyntax
│       │ │     │       │   ├─label: identifier("message")
│       │ │     │       │   ├─colon: colon
│       │ │     │       │   ╰─expression: StringLiteralExprSyntax
│       │ │     │       │     ├─openingQuote: stringQuote
│       │ │     │       │     ├─segments: StringLiteralSegmentListSyntax
│       │ │     │       │     │ ├─[0]: StringSegmentSyntax
│       │ │     │       │     │ │ ╰─content: stringSegment("No movies found matching the genre \'")
│       │ │     │       │     │ ├─[1]: ExpressionSegmentSyntax
│       │ │     │       │     │ │ ├─backslash: backslash
│       │ │     │       │     │ │ ├─leftParen: leftParen
│       │ │     │       │     │ │ ├─expressions: LabeledExprListSyntax
│       │ │     │       │     │ │ │ ╰─[0]: LabeledExprSyntax
│       │ │     │       │     │ │ │   ╰─expression: DeclReferenceExprSyntax
│       │ │     │       │     │ │ │     ╰─baseName: identifier("genre")
│       │ │     │       │     │ │ ╰─rightParen: rightParen
│       │ │     │       │     │ ╰─[2]: StringSegmentSyntax
│       │ │     │       │     │   ╰─content: stringSegment("\'.")
│       │ │     │       │     ╰─closingQuote: stringQuote
│       │ │     │       ├─rightParen: rightParen
│       │ │     │       ╰─additionalTrailingClosures: MultipleTrailingClosureElementListSyntax
│       │ │     ╰─rightBrace: rightBrace
│       │ ├─[2]: CodeBlockItemSyntax
│       │ │ ╰─item: VariableDeclSyntax
│       │ │   ├─attributes: AttributeListSyntax
│       │ │   ├─modifiers: DeclModifierListSyntax
│       │ │   ├─bindingSpecifier: keyword(SwiftSyntax.Keyword.var)
│       │ │   ╰─bindings: PatternBindingListSyntax
│       │ │     ╰─[0]: PatternBindingSyntax
│       │ │       ├─pattern: IdentifierPatternSyntax
│       │ │       │ ╰─identifier: identifier("randomMovies")
│       │ │       ├─typeAnnotation: TypeAnnotationSyntax
│       │ │       │ ├─colon: colon
│       │ │       │ ╰─type: ArrayTypeSyntax
│       │ │       │   ├─leftSquare: leftSquare
│       │ │       │   ├─element: IdentifierTypeSyntax
│       │ │       │   │ ╰─name: identifier("Movie")
│       │ │       │   ╰─rightSquare: rightSquare
│       │ │       ╰─initializer: InitializerClauseSyntax
│       │ │         ├─equal: equal
│       │ │         ╰─value: ArrayExprSyntax
│       │ │           ├─leftSquare: leftSquare
│       │ │           ├─elements: ArrayElementListSyntax
│       │ │           ╰─rightSquare: rightSquare
│       │ ├─[3]: CodeBlockItemSyntax
│       │ │ ╰─item: ForStmtSyntax
│       │ │   ├─forKeyword: keyword(SwiftSyntax.Keyword.for)
│       │ │   ├─pattern: WildcardPatternSyntax
│       │ │   │ ╰─wildcard: wildcard
│       │ │   ├─inKeyword: keyword(SwiftSyntax.Keyword.in)
│       │ │   ├─sequence: SequenceExprSyntax
│       │ │   │ ╰─elements: ExprListSyntax
│       │ │   │   ├─[0]: IntegerLiteralExprSyntax
│       │ │   │   │ ╰─literal: integerLiteral("0")
│       │ │   │   ├─[1]: BinaryOperatorExprSyntax
│       │ │   │   │ ╰─operator: binaryOperator("..<")
│       │ │   │   ╰─[2]: DeclReferenceExprSyntax
│       │ │   │     ╰─baseName: identifier("count")
│       │ │   ╰─body: CodeBlockSyntax
│       │ │     ├─leftBrace: leftBrace
│       │ │     ├─statements: CodeBlockItemListSyntax
│       │ │     │ ├─[0]: CodeBlockItemSyntax
│       │ │     │ │ ╰─item: GuardStmtSyntax
│       │ │     │ │   ├─guardKeyword: keyword(SwiftSyntax.Keyword.guard)
│       │ │     │ │   ├─conditions: ConditionElementListSyntax
│       │ │     │ │   │ ╰─[0]: ConditionElementSyntax
│       │ │     │ │   │   ╰─condition: OptionalBindingConditionSyntax
│       │ │     │ │   │     ├─bindingSpecifier: keyword(SwiftSyntax.Keyword.let)
│       │ │     │ │   │     ├─pattern: IdentifierPatternSyntax
│       │ │     │ │   │     │ ╰─identifier: identifier("randomMovie")
│       │ │     │ │   │     ╰─initializer: InitializerClauseSyntax
│       │ │     │ │   │       ├─equal: equal
│       │ │     │ │   │       ╰─value: FunctionCallExprSyntax
│       │ │     │ │   │         ├─calledExpression: MemberAccessExprSyntax
│       │ │     │ │   │         │ ├─base: DeclReferenceExprSyntax
│       │ │     │ │   │         │ │ ╰─baseName: identifier("movies")
│       │ │     │ │   │         │ ├─period: period
│       │ │     │ │   │         │ ╰─declName: DeclReferenceExprSyntax
│       │ │     │ │   │         │   ╰─baseName: identifier("randomElement")
│       │ │     │ │   │         ├─leftParen: leftParen
│       │ │     │ │   │         ├─arguments: LabeledExprListSyntax
│       │ │     │ │   │         ├─rightParen: rightParen
│       │ │     │ │   │         ╰─additionalTrailingClosures: MultipleTrailingClosureElementListSyntax
│       │ │     │ │   ├─elseKeyword: keyword(SwiftSyntax.Keyword.else)
│       │ │     │ │   ╰─body: CodeBlockSyntax
│       │ │     │ │     ├─leftBrace: leftBrace
│       │ │     │ │     ├─statements: CodeBlockItemListSyntax
│       │ │     │ │     │ ╰─[0]: CodeBlockItemSyntax
│       │ │     │ │     │   ╰─item: ThrowStmtSyntax
│       │ │     │ │     │     ├─throwKeyword: keyword(SwiftSyntax.Keyword.throw)
│       │ │     │ │     │     ╰─expression: MacroExpansionExprSyntax
│       │ │     │ │     │       ├─pound: pound
│       │ │     │ │     │       ├─macroName: identifier("RichError")
│       │ │     │ │     │       ├─leftParen: leftParen
│       │ │     │ │     │       ├─arguments: LabeledExprListSyntax
│       │ │     │ │     │       │ ├─[0]: LabeledExprSyntax
│       │ │     │ │     │       │ │ ├─label: identifier("code")
│       │ │     │ │     │       │ │ ├─colon: colon
│       │ │     │ │     │       │ │ ├─expression: IntegerLiteralExprSyntax
│       │ │     │ │     │       │ │ │ ╰─literal: integerLiteral("89316")
│       │ │     │ │     │       │ │ ╰─trailingComma: comma
│       │ │     │ │     │       │ ╰─[1]: LabeledExprSyntax
│       │ │     │ │     │       │   ├─label: identifier("message")
│       │ │     │ │     │       │   ├─colon: colon
│       │ │     │ │     │       │   ╰─expression: StringLiteralExprSyntax
│       │ │     │ │     │       │     ├─openingQuote: stringQuote
│       │ │     │ │     │       │     ├─segments: StringLiteralSegmentListSyntax
│       │ │     │ │     │       │     │ ├─[0]: StringSegmentSyntax
│       │ │     │ │     │       │     │ │ ╰─content: stringSegment("Not enough movies matching the genre \'")
│       │ │     │ │     │       │     │ ├─[1]: ExpressionSegmentSyntax
│       │ │     │ │     │       │     │ │ ├─backslash: backslash
│       │ │     │ │     │       │     │ │ ├─leftParen: leftParen
│       │ │     │ │     │       │     │ │ ├─expressions: LabeledExprListSyntax
│       │ │     │ │     │       │     │ │ │ ╰─[0]: LabeledExprSyntax
│       │ │     │ │     │       │     │ │ │   ╰─expression: DeclReferenceExprSyntax
│       │ │     │ │     │       │     │ │ │     ╰─baseName: identifier("genre")
│       │ │     │ │     │       │     │ │ ╰─rightParen: rightParen
│       │ │     │ │     │       │     │ ╰─[2]: StringSegmentSyntax
│       │ │     │ │     │       │     │   ╰─content: stringSegment("\'.")
│       │ │     │ │     │       │     ╰─closingQuote: stringQuote
│       │ │     │ │     │       ├─rightParen: rightParen
│       │ │     │ │     │       ╰─additionalTrailingClosures: MultipleTrailingClosureElementListSyntax
│       │ │     │ │     ╰─rightBrace: rightBrace
│       │ │     │ ├─[1]: CodeBlockItemSyntax
│       │ │     │ │ ╰─item: FunctionCallExprSyntax
│       │ │     │ │   ├─calledExpression: MemberAccessExprSyntax
│       │ │     │ │   │ ├─base: DeclReferenceExprSyntax
│       │ │     │ │   │ │ ╰─baseName: identifier("movies")
│       │ │     │ │   │ ├─period: period
│       │ │     │ │   │ ╰─declName: DeclReferenceExprSyntax
│       │ │     │ │   │   ╰─baseName: identifier("removeAll")
│       │ │     │ │   ├─arguments: LabeledExprListSyntax
│       │ │     │ │   ├─trailingClosure: ClosureExprSyntax
│       │ │     │ │   │ ├─leftBrace: leftBrace
│       │ │     │ │   │ ├─statements: CodeBlockItemListSyntax
│       │ │     │ │   │ │ ╰─[0]: CodeBlockItemSyntax
│       │ │     │ │   │ │   ╰─item: SequenceExprSyntax
│       │ │     │ │   │ │     ╰─elements: ExprListSyntax
│       │ │     │ │   │ │       ├─[0]: DeclReferenceExprSyntax
│       │ │     │ │   │ │       │ ╰─baseName: dollarIdentifier("$0")
│       │ │     │ │   │ │       ├─[1]: BinaryOperatorExprSyntax
│       │ │     │ │   │ │       │ ╰─operator: binaryOperator("==")
│       │ │     │ │   │ │       ╰─[2]: DeclReferenceExprSyntax
│       │ │     │ │   │ │         ╰─baseName: identifier("randomMovie")
│       │ │     │ │   │ ╰─rightBrace: rightBrace
│       │ │     │ │   ╰─additionalTrailingClosures: MultipleTrailingClosureElementListSyntax
│       │ │     │ ╰─[2]: CodeBlockItemSyntax
│       │ │     │   ╰─item: FunctionCallExprSyntax
│       │ │     │     ├─calledExpression: MemberAccessExprSyntax
│       │ │     │     │ ├─base: DeclReferenceExprSyntax
│       │ │     │     │ │ ╰─baseName: identifier("randomMovies")
│       │ │     │     │ ├─period: period
│       │ │     │     │ ╰─declName: DeclReferenceExprSyntax
│       │ │     │     │   ╰─baseName: identifier("append")
│       │ │     │     ├─leftParen: leftParen
│       │ │     │     ├─arguments: LabeledExprListSyntax
│       │ │     │     │ ╰─[0]: LabeledExprSyntax
│       │ │     │     │   ╰─expression: DeclReferenceExprSyntax
│       │ │     │     │     ╰─baseName: identifier("randomMovie")
│       │ │     │     ├─rightParen: rightParen
│       │ │     │     ╰─additionalTrailingClosures: MultipleTrailingClosureElementListSyntax
│       │ │     ╰─rightBrace: rightBrace
│       │ ╰─[4]: CodeBlockItemSyntax
│       │   ╰─item: ReturnStmtSyntax
│       │     ├─returnKeyword: keyword(SwiftSyntax.Keyword.return)
│       │     ╰─expression: DeclReferenceExprSyntax
│       │       ╰─baseName: identifier("randomMovies")
│       ╰─rightBrace: rightBrace
╰─rightBrace: rightBrace
*/
