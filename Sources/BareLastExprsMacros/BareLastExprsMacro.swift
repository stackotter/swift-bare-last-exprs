import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
@_spi(ExperimentalLanguageFeature) import SwiftSyntaxMacros

struct ExpansionError: LocalizedError {
    var errorDescription: String?

    init(_ message: String) {
        errorDescription = message
    }
}

final class BareLastExprRewriter: SyntaxRewriter {
    override func visit(_ statements: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        var statements = Array(super.visit(statements))

        // Explicitly return the last statement if it's an expression
        if let lastStatement = statements.last {
            statements[statements.count - 1] = switch lastStatement.item {
                case .expr(let expr):
                    Self.codeBlockItem(returning: expr)
                case .stmt(let stmt):
                    if let exprStmt = stmt.as(ExpressionStmtSyntax.self),
                        exprStmt.expression.is(IfExprSyntax.self) || exprStmt.expression.is(SwitchExprSyntax.self)
                    {
                        Self.codeBlockItem(returning: exprStmt.expression)
                    } else {
                        lastStatement
                    }
                case .decl:
                    lastStatement
            }
        }

        // Wrap the code block body in an immediately called closure so that
        // we can rely on the compiler's implicit returns to decide whether
        // the value should be returned or not. Otherwise we have to implement
        // a bunch of heurestics to guess whether a given function/closure
        // returns `Void` or not (a lot trickier for closures).
        let immediatelyCalledClosure = FunctionCallExprSyntax(
            calledExpression: ClosureExprSyntax(statements: CodeBlockItemListSyntax(statements)),
            leftParen: .leftParenToken(),
            arguments: [],
            rightParen: .rightParenToken()
        )

        return CodeBlockItemListSyntax([
            CodeBlockItemSyntax(item: .expr(ExprSyntax(immediatelyCalledClosure)))
        ])
    }

    // Not really sure why SwiftSyntax parses assignment of a switch/if statement to a variable as
    // SequenceExprSyntax, but it does, so we have to fix that up ourselves.
    override func visit(_ assignmentExpr: SequenceExprSyntax) -> ExprSyntax {
        let elements = assignmentExpr.elements
        guard elements.count == 3, elements[elements.index(at: 1)].is(AssignmentExprSyntax.self) else {
            return ExprSyntax(assignmentExpr)
        }

        return super.visit(InfixOperatorExprSyntax(
            leftOperand: elements[elements.index(at: 0)],
            operator: elements[elements.index(at: 1)],
            rightOperand: elements[elements.index(at: 2)]
        ))
    }

    static func codeBlockItem(returning expr: ExprSyntax) -> CodeBlockItemSyntax {
        // CodeBlockItemSyntax(item: .stmt(StmtSyntax(ReturnStmtSyntax(expression: expr))))
        var expr = expr
        expr.leadingTrivia = Trivia(pieces: [])
        expr.trailingTrivia = Trivia(pieces: [])
        return "return \(expr)"
    }
}

@_spi(ExperimentalLanguageFeature)
public struct BareLastExprsMacro: BodyMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        guard let body = declaration.body else {
            throw ExpansionError("Missing body")
        }

        guard let function = declaration.as(FunctionDeclSyntax.self) else {
            throw ExpansionError("@BareLastExprs can only be applied to function declarations")
        }

        // This check doesn't account for return types such as `((Void))` or `((()))` which
        // are also valid ways of writing `Void`.
        let returnsVoid: Bool
        if let returnClause = function.signature.returnClause {
            var returnType = returnClause.type
            returnType.leadingTrivia = Trivia(pieces: [])
            returnType.trailingTrivia = Trivia(pieces: [])
            returnsVoid = returnType.description == "Void" || returnType.description == "()"
        } else {
            returnsVoid = true
        }

        let statements = Array(BareLastExprRewriter().visit(body.statements))

        // Add an explicit return to the function's body (which shouldn't be necessary
        // due to the immediately called closure allowing us to make use of Swift's
        // in-built implicit returns). Required because a weird compiler bug rejects the
        // expanded code, even though if you write the same code manually it compiles
        // successfully.
        if !returnsVoid,
            statements.count == 1,
            let statement = statements.first,
            case let .expr(expr) = statement.item, expr.is(FunctionCallExprSyntax.self)
        {
            return [
                CodeBlockItemSyntax(item: .stmt(StmtSyntax(ReturnStmtSyntax(expression: expr))))
            ]
        } else {
            return statements
        }
    }
}

@main
struct BareLastExprsPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        BareLastExprsMacro.self,
    ]
}
