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

@_spi(ExperimentalLanguageFeature)
public struct ImplicitReturn: BodyMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        guard let body = declaration.body else {
            throw ExpansionError("Missing function body")
        }

        return Array(addExplicitReturns(to: body).statements)
    }

    static func codeBlockItem(returning expr: ExprSyntax) -> CodeBlockItemSyntax {
        // CodeBlockItemSyntax(item: .stmt(StmtSyntax(ReturnStmtSyntax(expression: expr))))
        var expr = expr
        expr.leadingTrivia = Trivia(pieces: [])
        expr.trailingTrivia = Trivia(pieces: [])
        return "return \(expr)"
    }

    static func addExplicitReturns(to codeBlock: CodeBlockSyntax) -> CodeBlockSyntax {
        var items: [CodeBlockItemSyntax] = Array(codeBlock.statements)

        if let lastStatement = items.last {
            items[items.count - 1] = switch lastStatement.item {
                case .expr(let expr):
                    codeBlockItem(returning: expr)
                case .stmt(let stmt):
                    if let exprStmt = stmt.as(ExpressionStmtSyntax.self) {
                        if let ifExpr = exprStmt.expression.as(IfExprSyntax.self) {
                            CodeBlockItemSyntax(item: .expr(ExprSyntax(
                                addExplicitReturns(to: ifExpr)
                            )))
                        } else if let switchExpr = exprStmt.expression.as(SwitchExprSyntax.self) {
                            CodeBlockItemSyntax(item: .expr(ExprSyntax(
                                addExplicitReturns(to: switchExpr)
                            )))
                        } else {
                            lastStatement
                        }
                    } else {
                        lastStatement
                    }
                case .decl:
                    lastStatement
            }
        }

        // Remove trivia to stop weird formatting issues
        items = items.map { item in
            var item = item
            item.leadingTrivia = Trivia(pieces: [])
            item.trailingTrivia = Trivia(pieces: [])
            return item
        }

        return CodeBlockSyntax(statements: CodeBlockItemListSyntax(items))
    }

    static func addExplicitReturns(to switchExpr: SwitchExprSyntax) -> SwitchExprSyntax {
        var switchExpr = switchExpr
        switchExpr.cases = SwitchCaseListSyntax(switchExpr.cases.map { switchCase in
            switch switchCase {
                case .switchCase(var switchCase):
                    switchCase.statements = addExplicitReturns(to: CodeBlockSyntax(statements: CodeBlockItemListSyntax(
                        switchCase.statements
                    ))).statements
                    return .switchCase(switchCase)
                case .ifConfigDecl:
                    // TODO
                    return switchCase
            }
        })
        return switchExpr
    }

    static func addExplicitReturns(to ifExpr: IfExprSyntax) -> IfExprSyntax {
        var ifExpr = ifExpr
        ifExpr.body = addExplicitReturns(to: ifExpr.body)
        switch ifExpr.elseBody {
            case .ifExpr(let elseIfExpr):
                ifExpr.elseBody = .ifExpr(addExplicitReturns(to: elseIfExpr))
            case .codeBlock(let elseBlock):
                ifExpr.elseBody = .codeBlock(addExplicitReturns(to: elseBlock))
            case .none:
                break
        }
        return ifExpr
    }
}

@main
struct ImplicitReturnPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ImplicitReturn.self,
    ]
}
