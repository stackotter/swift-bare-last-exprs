## Bare last expressions

Use if/switch exprs and implicit returns without being limited to single statement expressions!

Inspired by [the pitch for multi-statement if/switch expressions](https://forums.swift.org/t/pitch-multi-statement-if-switch-do-expressions/68443/443)
which lists bare last expressions as a considered alternative. I created this macro so that people
can play around with the ergonomics of bare last expressions in Swift.

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
