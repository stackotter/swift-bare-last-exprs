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
    override func visit(_ variableDecl: VariableDeclSyntax) -> DeclSyntax {
        var variableDecl = variableDecl
        variableDecl.bindings = PatternBindingListSyntax(variableDecl.bindings.map { binding in
            if var initializer = binding.initializer {
                initializer.value = Self.updateBareLastExprs(in: initializer.value)

                var binding = binding
                binding.initializer = initializer
                return binding
            } else {
                return binding
            }
        })
        return DeclSyntax(variableDecl)
    }

    // Not really sure why SwiftSyntax parses assignment of a switch/if statement to a variable as
    // SequenceExprSyntax, but it does.
    override func visit(_ assignmentExpr: SequenceExprSyntax) -> ExprSyntax {
        let elements = assignmentExpr.elements
        guard elements.count == 3, elements[elements.index(at: 1)].is(AssignmentExprSyntax.self) else {
            return ExprSyntax(assignmentExpr)
        }

        let value = assignmentExpr.elements[elements.index(at: 2)]

        var assignmentExpr = assignmentExpr
        assignmentExpr.elements[elements.index(at: 2)] = Self.updateBareLastExprs(in: value)
        return ExprSyntax(assignmentExpr)
    }

    override func visit(_ returnStmt: ReturnStmtSyntax) -> StmtSyntax {
        guard let expr = returnStmt.expression else {
            return StmtSyntax(returnStmt)
        }

        var returnStmt = returnStmt
        returnStmt.expression = Self.updateBareLastExprs(in: expr)
        return StmtSyntax(returnStmt)
    }

    static func updateBareLastExprs(in expr: ExprSyntax) -> ExprSyntax {
        let newExpr: ExprSyntax
        if let ifExpr = expr.as(IfExprSyntax.self) {
            newExpr = ExprSyntax(Self.addExplicitReturns(to: ifExpr))
        } else if let switchExpr = expr.as(SwitchExprSyntax.self) {
            newExpr = ExprSyntax(Self.addExplicitReturns(to: switchExpr))
        } else {
            return ExprSyntax(expr)
        }

        return ExprSyntax(
            BareLastExprsMacro.immediatelyCalledClosure(returning: newExpr)
        )
    }

    static func addExplicitReturns(to switchExpr: SwitchExprSyntax) -> SwitchExprSyntax {
        var switchExpr = switchExpr
        switchExpr.cases = SwitchCaseListSyntax(switchExpr.cases.map { switchCase in
            switch switchCase {
                case .switchCase(var switchCase):
                    switchCase.statements = BareLastExprsMacro.addExplicitReturn(to: CodeBlockSyntax(
                        statements: switchCase.statements
                    )).statements
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
        ifExpr.body = BareLastExprsMacro.addExplicitReturn(to: ifExpr.body)
        switch ifExpr.elseBody {
            case .ifExpr(let elseIfExpr):
                ifExpr.elseBody = .ifExpr(addExplicitReturns(to: elseIfExpr))
            case .codeBlock(let elseBlock):
                ifExpr.elseBody = .codeBlock(BareLastExprsMacro.addExplicitReturn(to: elseBlock))
            case .none:
                break
        }
        return ifExpr
    }
}

@_spi(ExperimentalLanguageFeature)
public struct BareLastExprsMacro: BodyMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        guard let function = declaration.as(FunctionDeclSyntax.self) else {
            throw ExpansionError("BareLastExprs can only be applied to functions")
        }

        guard var body = declaration.body else {
            throw ExpansionError("Missing function body")
        }

        // TODO: More rigorous return-type check (i.e. one that knows that `(Void)`
        //   is equivalent to `Void`).
        if let returnClause = function.signature.returnClause {
            var returnType = returnClause.type
            returnType.leadingTrivia = Trivia(pieces: [])
            returnType.trailingTrivia = Trivia(pieces: [])

            let isVoid = returnType.description == "Void" || returnType.description == "()"
            if !isVoid {
                body = addExplicitReturn(to: body)
            }
        }

        return Array(BareLastExprRewriter().visit(body).statements)
    }

    static func codeBlockItem(returning expr: ExprSyntax) -> CodeBlockItemSyntax {
        // CodeBlockItemSyntax(item: .stmt(StmtSyntax(ReturnStmtSyntax(expression: expr))))
        var expr = expr
        expr.leadingTrivia = Trivia(pieces: [])
        expr.trailingTrivia = Trivia(pieces: [])
        return "return \(expr)"
    }

    static func addExplicitReturn(to codeBlock: CodeBlockSyntax) -> CodeBlockSyntax {
        var items: [CodeBlockItemSyntax] = Array(codeBlock.statements)

        if let lastStatement = items.last {
            items[items.count - 1] = switch lastStatement.item {
                case .expr(let expr):
                    codeBlockItem(returning: expr)
                case .stmt(let stmt):
                    if let exprStmt = stmt.as(ExpressionStmtSyntax.self) {
                        if exprStmt.expression.is(IfExprSyntax.self) || exprStmt.expression.is(SwitchExprSyntax.self) {
                            codeBlockItem(returning: exprStmt.expression)
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

    static func immediatelyCalledClosure(returning expr: ExprSyntax) -> FunctionCallExprSyntax {
        FunctionCallExprSyntax(
            calledExpression: ClosureExprSyntax(statements: [
                CodeBlockItemSyntax(item: .stmt(StmtSyntax(ExpressionStmtSyntax(expression: expr))))
            ]),
            leftParen: .leftParenToken(),
            arguments: [],
            rightParen: .rightParenToken()
        )
    }
}

@main
struct BareLastExprsPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        BareLastExprsMacro.self,
    ]
}
