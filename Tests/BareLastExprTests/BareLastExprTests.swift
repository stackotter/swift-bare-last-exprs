import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(BareLastExprsMacros)
@_spi(ExperimentalLanguageFeature) import BareLastExprsMacros

let testMacros: [String: Macro.Type] = [
    "BareLastExprs": BareLastExprsMacro.self,
]
#endif

final class BareLastExprsTests: XCTestCase {
    func testSimpleLastExpr() throws {
        #if canImport(BareLastExprsMacros)
        assertMacroExpansion(
            """
            @BareLastExprs
            func add(_ lhs: Int, _ rhs: Int) -> Int {
                let result = lhs + rhs
                result
            }
            """,
            expandedSource: """
            func add(_ lhs: Int, _ rhs: Int) -> Int {
                return {
                    let result = lhs + rhs
                    return result
                }()
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLastExprIf() throws {
        #if canImport(BareLastExprsMacros)
        assertMacroExpansion(
            """
            @BareLastExprs
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
                return {
                    let result = lhs + rhs
                    return if result > max {
                        {
                                print("The result is greater than max")
                                return max
                        }()
                        } else if result < min {
                        {
                                print("The result is less than min")
                                return min
                        }()
                        } else {
                        {
                            return result
                        }()
                        }
                }()
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLastExprSwitch() throws {
        #if canImport(BareLastExprsMacros)
        assertMacroExpansion(
            """
            @BareLastExprs
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
                return {
                    print("Requesting fortune for \\(number)")
                    return switch number {
                            case 1:
                        {
                                    print("Warning: support for 1 is unstable")
                                    return "You have a long and prosperous future"
                        }()
                            case 2:
                        {
                            return "You must watch your back tomorrow (good luck...)"
                        }()
                            default:
                        {
                                    print("Warning: unknown number encountered (\\(number))")
                                    return "Unknown"
                        }()
                        }
                }()
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLastExprSwitchExprVarDecl() throws {
        #if canImport(BareLastExprsMacros)
        assertMacroExpansion(
            """
            @BareLastExprs
            func fortune(_ number: Int) -> String {
                print("Requesting fortune for \\(number)")
                let fortune = switch number {
                    case 1:
                        print("Warning: support for 1 is unstable")
                        "You have a long and prosperous future"
                    case 2:
                        "You must watch your back tomorrow (good luck...)"
                    default:
                        print("Warning: unknown number encountered (\\(number))")
                        "Unknown"
                }
                fortune
            }
            """,
            expandedSource: """
            func fortune(_ number: Int) -> String {
                return {
                    print("Requesting fortune for \\(number)")
                    let fortune = switch number {
                        case 1:
                        {
                                    print("Warning: support for 1 is unstable")
                                    return "You have a long and prosperous future"
                        }()
                        case 2:
                        {
                            return "You must watch your back tomorrow (good luck...)"
                        }()
                        default:
                        {
                                    print("Warning: unknown number encountered (\\(number))")
                                    return "Unknown"
                        }()
                    }
                    return fortune
                }()
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLastExprSwitchExprAssignment() throws {
        #if canImport(BareLastExprsMacros)
        assertMacroExpansion(
            """
            @BareLastExprs
            func fortune(_ number: Int) -> String {
                print("Requesting fortune for \\(number)")
                let fortune: String
                fortune = switch number {
                    case 1:
                        print("Warning: support for 1 is unstable")
                        "You have a long and prosperous future"
                    case 2:
                        "You must watch your back tomorrow (good luck...)"
                    default:
                        print("Warning: unknown number encountered (\\(number))")
                        "Unknown"
                }
                fortune
            }
            """,
            expandedSource: """
            func fortune(_ number: Int) -> String {
                return {
                    print("Requesting fortune for \\(number)")
                    let fortune: String
                    fortune = switch number {
                        case 1:
                        {
                                    print("Warning: support for 1 is unstable")
                                    return "You have a long and prosperous future"
                        }()
                        case 2:
                        {
                            return "You must watch your back tomorrow (good luck...)"
                        }()
                        default:
                        {
                                    print("Warning: unknown number encountered (\\(number))")
                                    return "Unknown"
                        }()
                    }
                    return fortune
                }()
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLastExprIfExprVarDecl() throws {
        #if canImport(BareLastExprsMacros)
        assertMacroExpansion(
            """
            @BareLastExprs
            func clampedAdd(_ lhs: Int, _ rhs: Int,  min: Int, max: Int) -> Int {
                let result = lhs + rhs
                let clampedResult = if result > max {
                    print("The result is greater than max")
                    max
                } else if result < min {
                    print("The result is less than min")
                    min
                } else {
                    result
                }
                clampedResult
            }
            """,
            expandedSource: """
            func clampedAdd(_ lhs: Int, _ rhs: Int,  min: Int, max: Int) -> Int {
                return {
                    let result = lhs + rhs
                    let clampedResult = if result > max {
                        {
                                print("The result is greater than max")
                                return max
                        }()
                    } else if result < min {
                        {
                                print("The result is less than min")
                                return min
                        }()
                    } else {
                        {
                            return result
                        }()
                    }
                    return clampedResult
                }()
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLastExprIfExprAssignment() throws {
        #if canImport(BareLastExprsMacros)
        assertMacroExpansion(
            """
            @BareLastExprs
            func clampedAdd(_ lhs: Int, _ rhs: Int,  min: Int, max: Int) -> Int {
                let result = lhs + rhs
                let clampedResult: Int
                clampedResult = if result > max {
                    print("The result is greater than max")
                    max
                } else if result < min {
                    print("The result is less than min")
                    min
                } else {
                    result
                }
                clampedResult
            }
            """,
            expandedSource: """
            func clampedAdd(_ lhs: Int, _ rhs: Int,  min: Int, max: Int) -> Int {
                return {
                    let result = lhs + rhs
                    let clampedResult: Int
                    clampedResult = if result > max {
                        {
                                print("The result is greater than max")
                                return max
                        }()
                    } else if result < min {
                        {
                                print("The result is less than min")
                                return min
                        }()
                    } else {
                        {
                            return result
                        }()
                    }
                    return clampedResult
                }()
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testClosureSimpleLastExpr() throws {
        #if canImport(BareLastExprsMacros)
        assertMacroExpansion(
            """
            @BareLastExprs
            func add(_ lhs: Int, _ rhs: Int) -> Int {
                let compute: () -> Int = {
                    let result = lhs + rhs
                    result
                }
                compute()
            }
            """,
            expandedSource: """
            func add(_ lhs: Int, _ rhs: Int) -> Int {
                return {
                    let compute: () -> Int = {
                        {
                                let result = lhs + rhs
                                return result
                        }()
                    }
                    return compute()
                }()
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
