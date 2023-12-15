import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(ImplicitReturnMacros)
@_spi(ExperimentalLanguageFeature) import ImplicitReturnMacros

let testMacros: [String: Macro.Type] = [
    "ImplicitReturn": ImplicitReturn.self,
]
#endif

final class ImplicitReturnTests: XCTestCase {
    func testSimpleLastExpr() throws {
        #if canImport(ImplicitReturnMacros)
        assertMacroExpansion(
            """
            @ImplicitReturn
            func add(_ lhs: Int, _ rhs: Int) -> Int {
                let result = lhs + rhs
                result
            }
            """,
            expandedSource: """
            func add(_ lhs: Int, _ rhs: Int) -> Int {
                let result = lhs + rhs
                return result
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLastExprIf() throws {
        #if canImport(ImplicitReturnMacros)
        assertMacroExpansion(
            """
            @ImplicitReturn
            func clampedAdd(_ lhs: Int, _ rhs: Int,  min: Int, max: Int) -> Int {
                let result = lhs + rhs
                if result > max {
                    print("The result is greater than max")
                    max
                } else if result < min {
                    print("The result is less than min")
                    min
                } else {
                    result
                }
            }
            """,
            expandedSource: """
            func clampedAdd(_ lhs: Int, _ rhs: Int,  min: Int, max: Int) -> Int {
                let result = lhs + rhs
                if result > max {
                    print("The result is greater than max")
                    return max
                } else if result < min {
                    print("The result is less than min")
                    return min
                } else {
                    return result
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLastExprSwitch() throws {
        #if canImport(ImplicitReturnMacros)
        assertMacroExpansion(
            """
            @ImplicitReturn
            func fortune(_ number: Int) -> String {
                print("Requesting fortune for \\(number)")
                switch number {
                    case 1:
                        print("Warning: support for 1 is unstable")
                        "You have a long and prosperous future"
                    case 2:
                        "You must watch your back tomorrow (good luck...)"
                    default:
                        print("Warning: unknown number encountered (\\(number))")
                        "Unknown"
                }
            }
            """,
            expandedSource: """
            func fortune(_ number: Int) -> String {
                print("Requesting fortune for \\(number)")
                switch number {
                        case 1:
                    print("Warning: support for 1 is unstable")
                    return "You have a long and prosperous future"
                        case 2:
                    return "You must watch your back tomorrow (good luck...)"
                        default:
                    print("Warning: unknown number encountered (\\(number))")
                    return "Unknown"
                    }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}