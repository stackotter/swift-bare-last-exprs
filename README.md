## Bare last expressions

This macro was built to try out a potential syntax for multi-statement if/switch expressions
in Swift before [the pitch for multi-statement if/switch expressions](https://forums.swift.org/t/pitch-multi-statement-if-switch-do-expressions/68443/443)
lands.

When a function is annotated with `@BareLastExprs`, the last expression in a multi-statement
if/switch expression branch is used as the result. For fullness, the last expression in
a function or closure body is implicitly returned. Together these allow for quite neat code in
my opinion.

The following code sample shows off a variety of complex expressions with implicit returns
powered by the `@BareLastExprs` function body macro.

```swift
@BareLastExprs
func fortune(_ number: Int) -> String {
    print("Requesting fortune for \(number)")
    let fortune = switch number {
        case 1, 3, 5:
            print("Warning: Support for odd numbers is unstable")
            if number == 3 {
                "You have a long and prosperous future"
            } else {
                "Your future looks bleak"
            }
        case 2, 4, 6:
            if number == 6 {
                "You must watch your back tomorrow (good luck...)"
            } else {
                "Your shoes will develop an untimely hole"
            }
        default:
            print("Warning: I've never encountered \(number) before")
            "Spaghetti will fall, meatballs will rise"
    }

    print("Processing...")

    if Int.random(in: 0..<10) == 0 {
        print("Warning: Quantum interference detected in RAM")
        "Fortune got corrupted, please try again"
    } else {
        fortune
    }
}
```

### Usage

Since function body macros haven't landed yet, you'll have to download the latest toolchain
snapshot and enable the experimental `BodyMacros` features. I've been using
[the 2023-12-07 toolchain (macOS)](https://download.swift.org/development/xcode/swift-DEVELOPMENT-SNAPSHOT-2023-12-07-a/swift-DEVELOPMENT-SNAPSHOT-2023-12-07-a-osx.pkg),
but any newer toolchains should also work. I haven't tested the macro on Linux yet, let me know
if it works!

```sh
/Library/Developer/Toolchains/swift-DEVELOPMENT-SNAPSHOT-XXXX-XX-XX-x.xctoolchain/usr/bin/swift run -Xswiftc -enable-experimental-feature -Xswiftc BodyMacros
```

Be aware that you may get weird compiler crashes if you try to run the example with **Xcode**,
I'm not really sure what's causing it, but I don't think it's the macro's fault. Copying
and pasting the expanded code and compiling that runs fine.

### Known limitations

The macro wraps code blocks in closures to implement bare last expressions. Which means
that assignments to uninitialized variables won't compile (sorry definite initialization).

```swift
let opposite: Int
let value = if condition {
    opposite = 0 // cannot assign to value: 'opposite' is a 'let' constant
    1
} else {
    opposite = 1 // cannot assign to value: 'opposite' is a 'let' constant
    0
}
```
